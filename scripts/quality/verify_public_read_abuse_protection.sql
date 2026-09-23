-- Controlled SQL verifier for migrations 14 + 15. All fixtures roll back.
-- Complements, but does not replace, the real HTTP integration gate.
begin read only;
select set_config('request.path', '/rpc/get_fresh_cached_product', true);
select set_config('request.method', 'POST', true);
select set_config('request.headers', '{"x-forwarded-for":"198.51.100.44"}', true);
set local role anon;
do $$
begin
  begin
    perform public.enforce_public_read_rate_limit();
    raise exception 'counter write unexpectedly succeeded in READ ONLY';
  exception when read_only_sql_transaction then
    null; -- Shows why the protected public RPCs must be VOLATILE.
  end;
end;
$$;
rollback;

begin read write;
do $$
declare
  v_role text;
  v_function text;
begin
  if not exists (
    select 1 from pg_db_role_setting as settings
    join pg_roles as roles on roles.oid = settings.setrole
    cross join lateral unnest(settings.setconfig) as setting
    where roles.rolname = 'authenticator'
      and setting = 'pgrst.db_pre_request=public.enforce_public_read_rate_limit'
  ) then
    raise exception 'public read pre-request hook is not configured';
  end if;
  if not exists (
    select 1 from cron.job
    where jobname = 'scanfair-public-read-rate-cleanup'
      and schedule = '*/5 * * * *'
      and command = 'select private.cleanup_public_read_rate_windows();'
      and database = 'postgres' and username = 'postgres' and active
  ) then
    raise exception 'public read rate cleanup job is not configured';
  end if;
  foreach v_role in array array['anon', 'authenticated', 'service_role'] loop
    if not has_function_privilege(v_role, 'public.enforce_public_read_rate_limit()', 'EXECUTE') then
      raise exception 'request role % cannot execute the hook', v_role;
    end if;
    if has_table_privilege(v_role, 'private.public_read_rate_windows', 'SELECT,INSERT,UPDATE,DELETE') then
      raise exception 'rate-window table exposed to %', v_role;
    end if;
  end loop;
  foreach v_function in array array[
    'public.get_fresh_cached_product(text,text)',
    'public.get_published_product_evidence(text)',
    'public.get_published_score_snapshot(text,text)'
  ] loop
    if (select provolatile from pg_proc where oid = v_function::regprocedure) is distinct from 'v' then
      raise exception 'RPC % does not use a writable PostgREST transaction', v_function;
    end if;
  end loop;
end;
$$;

-- Only reserved documentation-address fixture rows are touched, then restored.
delete from private.public_read_rate_windows
where subject_hash = encode(extensions.digest(
  convert_to('scanfair-public-read-rate-v1|' || '198.51.100.44'::inet::text, 'UTF8'),
  'sha256'), 'hex');
select set_config('request.path', '/rpc/get_fresh_cached_product', true);
select set_config('request.method', 'POST', true);
select set_config('request.headers', '{"x-forwarded-for":"203.0.113.99, 198.51.100.44"}', true);
set local role anon;
do $$
declare
  v_error text;
begin
  for attempt in 1..30 loop
    perform set_config('request.headers', format(
      '{"x-forwarded-for":"203.0.113.%s, 198.51.100.44"}', attempt
    ), true);
    perform public.enforce_public_read_rate_limit();
  end loop;
  perform set_config('request.headers', '{"x-forwarded-for":"203.0.113.31, 198.51.100.44"}', true);
  begin
    perform public.enforce_public_read_rate_limit();
    raise exception 'thirty-first request unexpectedly admitted';
  exception when sqlstate 'PGRST' then
    get stacked diagnostics v_error = message_text;
    if v_error not like '%public_read_rate_limit_exceeded%' then
      raise exception 'unexpected rate denial: %', v_error;
    end if;
  end;
end;
$$;
reset role;
do $$
declare
  v_count integer;
begin
  select request_count into v_count from private.public_read_rate_windows
  where subject_hash = encode(extensions.digest(
    convert_to('scanfair-public-read-rate-v1|' || '198.51.100.44'::inet::text, 'UTF8'),
    'sha256'), 'hex')
    and window_started_at = date_trunc('minute', clock_timestamp());
  if v_count is distinct from 30 then
    raise exception 'expected counter 30, found %', v_count;
  end if;
end;
$$;

set local role authenticated;
select set_config('request.method', 'GET', true);
do $$
declare
  v_path text;
  v_error text;
begin
  foreach v_path in array array[
    '/rpc/get_fresh_cached_product',
    '/rpc/get_published_product_evidence',
    '/rpc/get_published_score_snapshot',
    '/rpc/get_fresh_cached_product/'
  ] loop
    perform set_config('request.path', v_path, true);
    begin
      perform public.enforce_public_read_rate_limit();
      raise exception 'GET bypass at %', v_path;
    exception when sqlstate 'PGRST' then
      get stacked diagnostics v_error = message_text;
      if v_error not like '%public_read_method_not_allowed%' then raise; end if;
    end;
  end loop;
  perform set_config('request.method', 'POST', true);
  perform set_config('request.headers', '{}', true);
  begin
    perform public.enforce_public_read_rate_limit();
    raise exception 'missing identity bypass';
  exception when sqlstate 'PGRST' then
    get stacked diagnostics v_error = message_text;
    if v_error not like '%public_read_identity_unavailable%' then raise; end if;
  end;
  perform set_config('request.headers', '{"x-forwarded-for":"not-an-ip"}', true);
  begin
    perform public.enforce_public_read_rate_limit();
    raise exception 'invalid identity bypass';
  exception when sqlstate 'PGRST' then
    get stacked diagnostics v_error = message_text;
    if v_error not like '%public_read_identity_invalid%' then raise; end if;
  end;
  foreach v_path in array array[
    '/rpc/%67et_fresh_cached_product', '/rpc//get_fresh_cached_product'
  ] loop
    perform set_config('request.path', v_path, true);
    begin
      perform public.enforce_public_read_rate_limit();
      raise exception 'ambiguous path bypass at %', v_path;
    exception when sqlstate 'PGRST' then
      get stacked diagnostics v_error = message_text;
      if v_error not like '%public_read_path_invalid%' then raise; end if;
    end;
  end loop;
end;
$$;
reset role;
set local role service_role;
select set_config('request.path', '/rpc/claim_writer_capacity', true);
select public.enforce_public_read_rate_limit();
reset role;
rollback;
