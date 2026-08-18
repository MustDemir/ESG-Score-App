do $verification$
declare
  v_now timestamptz := pg_catalog.clock_timestamp();
  v_cleanup jsonb;
  v_status text;
  v_rate_windows_expected integer;
  v_cached_products_expected integer;
  v_idempotency_keys_expected integer;
  v_audit_records_expected integer;
  v_daily_usage_expected integer;
  v_cron_history_expected integer;
begin
  if not exists (
    select 1
    from pg_catalog.pg_extension
    where extname = 'pg_cron' and extversion = '1.6.4'
  ) then
    raise exception 'pg_cron 1.6.4 is not installed';
  end if;

  if (
    select count(*)
    from cron.job
    where jobname = 'scanfair-retention-cleanup'
      and schedule = '20 3 * * *'
      and command = 'select private.run_retention_cleanup();'
      and database = 'postgres'
      and username = 'postgres'
      and active
  ) <> 1 then
    raise exception 'retention cleanup cron identity or schedule is invalid';
  end if;

  if pg_catalog.has_function_privilege(
    'service_role', 'private.run_retention_cleanup(timestamptz)', 'execute'
  ) then
    raise exception 'service_role can execute private retention cleanup';
  end if;

  if pg_catalog.has_table_privilege(
    'service_role', 'private.writer_record_watermarks', 'select'
  ) then
    raise exception 'service_role can read private writer watermarks';
  end if;

  if exists (
    select 1 from public.cached_products
    where barcode in ('50999997', '50999998')
  ) or exists (
    select 1 from private.writer_record_watermarks
    where source_record_id in ('50999997', '50999998')
  ) then
    raise exception 'remote retention verification fixture collision';
  end if;

  -- This exception block is a PostgreSQL subtransaction. The sentinel rolls
  -- back every fixture and cleanup effect before it is handled as success.
  begin
    begin
      perform public.publish_off_product(
        'remote-retention-future',
        'remote-retention-future-correlation',
        'scheduled_ingestion_job',
        '50999996',
        '{"code":"50999996","product_name":"Future fixture"}'::jsonb,
        v_now,
        v_now + interval '1 day',
        v_now + interval '2 days',
        'v3'
      );
      raise exception 'future writer clock unexpectedly succeeded';
    exception
      when sqlstate '22023' then
        if sqlerrm <> 'invalid writer timestamps' then
          raise;
        end if;
    end;

    perform public.publish_off_product(
      'remote-retention-old',
      'remote-retention-old-correlation',
      'scheduled_ingestion_job',
      '50999997',
      '{"code":"50999997","product_name":"Old fixture"}'::jsonb,
      v_now - interval '6 days',
      v_now - interval '5 days',
      v_now - interval '25 hours',
      'v3'
    );
    perform public.publish_off_product(
      'remote-retention-fresh',
      'remote-retention-fresh-correlation',
      'scheduled_ingestion_job',
      '50999998',
      '{"code":"50999998","product_name":"Fresh fixture"}'::jsonb,
      v_now - interval '1 hour',
      v_now,
      v_now + interval '6 days',
      'v3'
    );

    update private.writer_idempotency_keys
    set created_at = v_now - interval '31 days'
    where source_record_id = '50999997';

    insert into private.writer_rate_windows (
      scope, actor_type, window_started_at, request_count
    ) values
      ('actor', 'remote-retention-old', v_now - interval '2 hours', 1),
      ('actor', 'remote-retention-fresh', v_now - interval '30 minutes', 1);

    insert into private.writer_daily_usage (usage_date, upstream_request_count)
    values
      ((v_now at time zone 'UTC')::date - 401, 1),
      ((v_now at time zone 'UTC')::date - 399, 1);

    insert into private.writer_audit_log (
      request_id, idempotency_key, actor_type, action, source_id,
      target_record, input_sha256, outcome, status_code, started_at,
      completed_at, correlation_id, created_at
    ) values (
      'remote-retention-expired-audit',
      pg_catalog.repeat('e', 64),
      'scheduled_ingestion_job',
      'fetch_product_cache',
      'open-food-facts',
      '50999999',
      pg_catalog.repeat('e', 64),
      'not_found',
      404,
      v_now - interval '91 days',
      v_now - interval '91 days',
      'remote-retention-expired-correlation',
      v_now - interval '91 days'
    );

    insert into cron.job_run_details (
      jobid, runid, database, username, command, status, start_time, end_time
    ) values
      (
        (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
        -9201, current_database(), current_user, 'remote-retention-old',
        'succeeded', v_now - interval '31 days', v_now - interval '31 days'
      ),
      (
        (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
        -9202, current_database(), current_user, 'remote-retention-fresh',
        'succeeded', v_now - interval '29 days', v_now - interval '29 days'
      );

    begin
      delete from private.writer_audit_log
      where request_id = 'remote-retention-expired-audit';
      raise exception 'direct audit deletion unexpectedly succeeded';
    exception
      when sqlstate 'P0001' then
        if sqlerrm <> 'writer audit records are append-only' then
          raise;
        end if;
    end;

    begin
      perform private.run_retention_cleanup(v_now + interval '1 day');
      raise exception 'future cleanup clock unexpectedly succeeded';
    exception
      when sqlstate '22023' then
        if sqlerrm <> 'cleanup clock cannot be in the future' then
          raise;
        end if;
    end;

    select least(count(*), 10000)::integer
    into v_rate_windows_expected
    from private.writer_rate_windows
    where window_started_at < v_now - interval '1 hour';

    select least(count(*), 10000)::integer
    into v_cached_products_expected
    from public.cached_products
    where expires_at < v_now - interval '1 day';

    select least(count(*), 10000)::integer
    into v_idempotency_keys_expected
    from private.writer_idempotency_keys
    where created_at < v_now - interval '30 days';

    select least(count(*), 10000)::integer
    into v_audit_records_expected
    from private.writer_audit_log
    where created_at < v_now - interval '90 days';

    select count(*)::integer
    into v_daily_usage_expected
    from private.writer_daily_usage
    where usage_date < (v_now at time zone 'UTC')::date - 400;

    select least(count(*), 10000)::integer
    into v_cron_history_expected
    from cron.job_run_details
    where end_time < v_now - interval '30 days';

    v_cleanup := private.run_retention_cleanup(v_now);
    if (v_cleanup ->> 'rate_windows_deleted')::integer <> v_rate_windows_expected
      or (v_cleanup ->> 'cached_products_deleted')::integer <> v_cached_products_expected
      or (v_cleanup ->> 'idempotency_keys_deleted')::integer <> v_idempotency_keys_expected
      or (v_cleanup ->> 'audit_records_deleted')::integer <> v_audit_records_expected
      or (v_cleanup ->> 'daily_usage_deleted')::integer <> v_daily_usage_expected
      or (v_cleanup ->> 'cron_history_deleted')::integer <> v_cron_history_expected
    then
      raise exception 'retention cleanup counts are invalid: %', v_cleanup;
    end if;

    if exists (
      select 1 from public.cached_products where barcode = '50999997'
    ) or not exists (
      select 1 from public.cached_products where barcode = '50999998'
    ) or not exists (
      select 1 from private.writer_record_watermarks
      where source_record_id = '50999997'
    ) or exists (
      select 1 from private.writer_rate_windows
      where actor_type = 'remote-retention-old'
    ) or not exists (
      select 1 from private.writer_rate_windows
      where actor_type = 'remote-retention-fresh'
    ) or exists (
      select 1 from private.writer_idempotency_keys
      where source_record_id = '50999997'
    ) or exists (
      select 1 from private.writer_audit_log
      where request_id = 'remote-retention-expired-audit'
    ) or exists (
      select 1 from private.writer_daily_usage
      where usage_date = (v_now at time zone 'UTC')::date - 401
    ) or not exists (
      select 1 from private.writer_daily_usage
      where usage_date = (v_now at time zone 'UTC')::date - 399
    ) or exists (
      select 1 from cron.job_run_details where runid = -9201
    ) or not exists (
      select 1 from cron.job_run_details where runid = -9202
    ) then
      raise exception 'retention fixture boundary or durable watermark is invalid';
    end if;

    v_status := public.publish_off_product(
      'remote-retention-replay',
      'remote-retention-replay-correlation',
      'scheduled_ingestion_job',
      '50999997',
      '{"code":"50999997","product_name":"Old fixture"}'::jsonb,
      v_now - interval '6 days',
      v_now,
      v_now + interval '6 days',
      'v3'
    ) ->> 'status';
    if v_status <> 'duplicate_existing' then
      raise exception 'exact replay did not restore cache: %', v_status;
    end if;

    v_status := public.publish_off_product(
      'remote-retention-older',
      'remote-retention-older-correlation',
      'scheduled_ingestion_job',
      '50999997',
      '{"code":"50999997","product_name":"Older fixture"}'::jsonb,
      v_now - interval '7 days',
      v_now,
      v_now + interval '6 days',
      'v3'
    ) ->> 'status';
    if v_status <> 'rejected_older_observation' then
      raise exception 'older replay was not rejected: %', v_status;
    end if;

    v_status := public.publish_off_product(
      'remote-retention-conflict',
      'remote-retention-conflict-correlation',
      'scheduled_ingestion_job',
      '50999997',
      '{"code":"50999997","product_name":"Conflict fixture"}'::jsonb,
      v_now - interval '6 days',
      v_now,
      v_now + interval '6 days',
      'v3'
    ) ->> 'status';
    if v_status <> 'rejected_conflicting_observation' then
      raise exception 'conflicting replay was not rejected: %', v_status;
    end if;

    raise exception 'SCANFAIR_RETENTION_VERIFICATION_ROLLBACK';
  exception
    when raise_exception then
      if sqlerrm <> 'SCANFAIR_RETENTION_VERIFICATION_ROLLBACK' then
        raise;
      end if;
  end;

  if exists (
    select 1 from public.cached_products
    where barcode in ('50999996', '50999997', '50999998')
  ) or exists (
    select 1 from private.writer_record_watermarks
    where source_record_id in ('50999996', '50999997', '50999998')
  ) or exists (
    select 1 from private.writer_audit_log
    where request_id like 'remote-retention-%'
  ) or exists (
    select 1 from cron.job_run_details
    where runid in (-9201, -9202)
  ) then
    raise exception 'remote retention verification left fixtures behind';
  end if;
end
$verification$;
