create table if not exists private.retention_health_checks (
  check_id bigint generated always as identity primary key,
  checked_at timestamptz not null default clock_timestamp(),
  health_status text not null
    check (health_status in ('healthy', 'warning', 'critical')),
  latest_cleanup_run_id bigint,
  latest_cleanup_status text,
  latest_cleanup_started_at timestamptz,
  latest_cleanup_ended_at timestamptz,
  latest_cleanup_duration_ms bigint,
  eligible_backlog jsonb not null,
  total_writer_audit_rows bigint not null check (total_writer_audit_rows >= 0),
  breach_codes text[] not null default '{}',
  details jsonb not null default '{}'::jsonb
);

create index if not exists retention_health_checks_checked_at_idx
  on private.retention_health_checks (checked_at desc);

create table if not exists private.retention_alert_outbox (
  alert_id bigint generated always as identity primary key,
  alert_code text not null,
  severity text not null check (severity in ('warning', 'critical')),
  lifecycle_status text not null check (lifecycle_status in ('open', 'resolved')),
  delivery_status text not null check (
    delivery_status in (
      'not_configured_runtime_disabled',
      'pending',
      'delivered',
      'delivery_failed'
    )
  ),
  first_detected_at timestamptz not null,
  last_detected_at timestamptz not null,
  resolved_at timestamptz,
  occurrence_count integer not null default 1 check (occurrence_count > 0),
  payload jsonb not null,
  check (
    (lifecycle_status = 'open' and resolved_at is null)
    or (lifecycle_status = 'resolved' and resolved_at is not null)
  )
);

create unique index if not exists retention_alert_outbox_one_open_code_idx
  on private.retention_alert_outbox (alert_code)
  where lifecycle_status = 'open';

create index if not exists retention_alert_outbox_detected_idx
  on private.retention_alert_outbox (last_detected_at desc);

alter table private.retention_health_checks enable row level security;
alter table private.retention_alert_outbox enable row level security;

revoke all on table private.retention_health_checks
  from public, anon, authenticated, service_role;
revoke all on table private.retention_alert_outbox
  from public, anon, authenticated, service_role;
revoke all on sequence private.retention_health_checks_check_id_seq
  from public, anon, authenticated, service_role;
revoke all on sequence private.retention_alert_outbox_alert_id_seq
  from public, anon, authenticated, service_role;

create or replace function private.retention_health_snapshot(
  p_now timestamptz default clock_timestamp()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cleanup_job_count integer;
  v_monitor_job_count integer;
  v_cleanup_job_id bigint;
  v_latest_run_id bigint;
  v_latest_status text;
  v_latest_started_at timestamptz;
  v_latest_ended_at timestamptz;
  v_latest_duration_ms bigint;
  v_latest_success_at timestamptz;
  v_three_slow_runs boolean := false;
  v_rate_windows bigint;
  v_cached_products bigint;
  v_idempotency_keys bigint;
  v_audit_records bigint;
  v_daily_usage bigint;
  v_cron_history bigint;
  v_total_audit_rows bigint;
  v_prior_backlog_checks integer := 0;
  v_breach_codes text[] := '{}'::text[];
  v_health_status text := 'healthy';
begin
  if p_now > clock_timestamp() + interval '5 minutes' then
    raise exception 'retention health clock cannot be in the future'
      using errcode = '22023';
  end if;

  select count(*)::integer, min(jobid)
  into v_cleanup_job_count, v_cleanup_job_id
  from cron.job
  where jobname = 'scanfair-retention-cleanup'
    and schedule = '20 3 * * *'
    and command = 'select private.run_retention_cleanup();'
    and database = 'postgres'
    and username = 'postgres'
    and active;

  select count(*)::integer
  into v_monitor_job_count
  from cron.job
  where jobname = 'scanfair-retention-health-monitor'
    and schedule = '30 3 * * *'
    and command = 'select private.record_retention_health();'
    and database = 'postgres'
    and username = 'postgres'
    and active;

  if v_cleanup_job_count <> 1 then
    v_breach_codes := array_append(
      v_breach_codes, 'cleanup_job_configuration_invalid'
    );
  end if;
  if v_monitor_job_count <> 1 then
    v_breach_codes := array_append(
      v_breach_codes, 'monitor_job_configuration_invalid'
    );
  end if;

  select runid, status, start_time, end_time,
         case
           when start_time is not null and end_time is not null then
             (extract(epoch from (end_time - start_time)) * 1000)::bigint
           else null
         end
  into v_latest_run_id, v_latest_status, v_latest_started_at,
       v_latest_ended_at, v_latest_duration_ms
  from cron.job_run_details
  where jobid = v_cleanup_job_id
  order by start_time desc
  limit 1;

  select max(end_time)
  into v_latest_success_at
  from cron.job_run_details
  where jobid = v_cleanup_job_id
    and status = 'succeeded';

  if v_latest_success_at is null
     or v_latest_success_at < p_now - interval '36 hours' then
    v_breach_codes := array_append(
      v_breach_codes, 'cleanup_success_stale'
    );
  end if;

  if v_latest_status is distinct from 'succeeded' then
    v_breach_codes := array_append(
      v_breach_codes, 'cleanup_latest_run_failed'
    );
  end if;

  select count(*) = 3 and bool_and(
           status = 'succeeded'
           and start_time is not null
           and end_time is not null
           and end_time - start_time > interval '2 seconds'
         )
  into v_three_slow_runs
  from (
    select status, start_time, end_time
    from cron.job_run_details
    where jobid = v_cleanup_job_id
    order by start_time desc
    limit 3
  ) recent_runs;

  select count(*) into v_rate_windows
  from private.writer_rate_windows
  where window_started_at < p_now - interval '1 hour';

  select count(*) into v_cached_products
  from public.cached_products
  where expires_at < p_now - interval '1 day';

  select count(*) into v_idempotency_keys
  from private.writer_idempotency_keys
  where created_at < p_now - interval '30 days';

  select count(*) into v_audit_records
  from private.writer_audit_log
  where created_at < p_now - interval '90 days';

  select count(*) into v_daily_usage
  from private.writer_daily_usage
  where usage_date < (p_now at time zone 'UTC')::date - 400;

  select count(*) into v_cron_history
  from cron.job_run_details
  where end_time < p_now - interval '30 days';

  select count(*) into v_total_audit_rows
  from private.writer_audit_log;

  if greatest(
    v_rate_windows,
    v_cached_products,
    v_idempotency_keys,
    v_audit_records,
    v_cron_history
  ) >= 10000 then
    v_breach_codes := array_append(
      v_breach_codes, 'cleanup_backlog_at_or_above_batch'
    );

    select count(*)::integer
    into v_prior_backlog_checks
    from (
      select eligible_backlog
      from private.retention_health_checks
      order by checked_at desc
      limit 6
    ) prior
    where greatest(
      coalesce((eligible_backlog ->> 'writer_rate_windows')::bigint, 0),
      coalesce((eligible_backlog ->> 'cached_products')::bigint, 0),
      coalesce((eligible_backlog ->> 'writer_idempotency_keys')::bigint, 0),
      coalesce((eligible_backlog ->> 'writer_audit_log')::bigint, 0),
      coalesce((eligible_backlog ->> 'cron_job_run_details')::bigint, 0)
    ) >= 10000;

    if v_prior_backlog_checks = 6 then
      v_breach_codes := array_append(
        v_breach_codes, 'cleanup_backlog_persistent_seven_checks'
      );
    end if;
  end if;

  if v_three_slow_runs then
    v_breach_codes := array_append(
      v_breach_codes, 'cleanup_duration_partition_review'
    );
  end if;

  if v_total_audit_rows >= 1000000 then
    v_breach_codes := array_append(
      v_breach_codes, 'writer_audit_partition_review'
    );
  end if;

  if v_breach_codes && array[
    'cleanup_job_configuration_invalid',
    'monitor_job_configuration_invalid',
    'cleanup_success_stale',
    'cleanup_latest_run_failed',
    'cleanup_backlog_persistent_seven_checks'
  ] then
    v_health_status := 'critical';
  elsif cardinality(v_breach_codes) > 0 then
    v_health_status := 'warning';
  end if;

  return jsonb_build_object(
    'checked_at', p_now,
    'health_status', v_health_status,
    'latest_cleanup_run', jsonb_build_object(
      'run_id', v_latest_run_id,
      'status', v_latest_status,
      'started_at', v_latest_started_at,
      'ended_at', v_latest_ended_at,
      'duration_ms', v_latest_duration_ms,
      'latest_success_at', v_latest_success_at
    ),
    'eligible_backlog', jsonb_build_object(
      'writer_rate_windows', v_rate_windows,
      'cached_products', v_cached_products,
      'writer_idempotency_keys', v_idempotency_keys,
      'writer_audit_log', v_audit_records,
      'writer_daily_usage', v_daily_usage,
      'cron_job_run_details', v_cron_history
    ),
    'total_writer_audit_rows', v_total_audit_rows,
    'breach_codes', to_jsonb(v_breach_codes),
    'external_delivery', 'not_configured_runtime_disabled'
  );
end;
$$;

create or replace function private.record_retention_health(
  p_now timestamptz default clock_timestamp()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_snapshot jsonb;
  v_check_id bigint;
  v_codes text[];
  v_code text;
  v_severity text;
begin
  v_snapshot := private.retention_health_snapshot(p_now);

  select coalesce(array_agg(value), '{}'::text[])
  into v_codes
  from jsonb_array_elements_text(v_snapshot -> 'breach_codes');

  insert into private.retention_health_checks (
    checked_at,
    health_status,
    latest_cleanup_run_id,
    latest_cleanup_status,
    latest_cleanup_started_at,
    latest_cleanup_ended_at,
    latest_cleanup_duration_ms,
    eligible_backlog,
    total_writer_audit_rows,
    breach_codes,
    details
  ) values (
    p_now,
    v_snapshot ->> 'health_status',
    (v_snapshot #>> '{latest_cleanup_run,run_id}')::bigint,
    v_snapshot #>> '{latest_cleanup_run,status}',
    (v_snapshot #>> '{latest_cleanup_run,started_at}')::timestamptz,
    (v_snapshot #>> '{latest_cleanup_run,ended_at}')::timestamptz,
    (v_snapshot #>> '{latest_cleanup_run,duration_ms}')::bigint,
    v_snapshot -> 'eligible_backlog',
    (v_snapshot ->> 'total_writer_audit_rows')::bigint,
    v_codes,
    v_snapshot
  ) returning check_id into v_check_id;

  foreach v_code in array v_codes loop
    v_severity := case
      when v_code = any(array[
        'cleanup_job_configuration_invalid',
        'monitor_job_configuration_invalid',
        'cleanup_success_stale',
        'cleanup_latest_run_failed',
        'cleanup_backlog_persistent_seven_checks'
      ]) then 'critical'
      else 'warning'
    end;

    insert into private.retention_alert_outbox (
      alert_code,
      severity,
      lifecycle_status,
      delivery_status,
      first_detected_at,
      last_detected_at,
      payload
    ) values (
      v_code,
      v_severity,
      'open',
      'not_configured_runtime_disabled',
      p_now,
      p_now,
      v_snapshot
    )
    on conflict (alert_code) where lifecycle_status = 'open'
    do update set
      severity = excluded.severity,
      last_detected_at = excluded.last_detected_at,
      occurrence_count = private.retention_alert_outbox.occurrence_count + 1,
      payload = excluded.payload;
  end loop;

  update private.retention_alert_outbox
  set lifecycle_status = 'resolved',
      resolved_at = p_now,
      last_detected_at = p_now
  where lifecycle_status = 'open'
    and not (alert_code = any(v_codes));

  return v_snapshot || jsonb_build_object(
    'check_id', v_check_id,
    'open_alert_count', (
      select count(*)
      from private.retention_alert_outbox
      where lifecycle_status = 'open'
    )
  );
end;
$$;

revoke all on function private.retention_health_snapshot(timestamptz)
  from public, anon, authenticated, service_role;
revoke all on function private.record_retention_health(timestamptz)
  from public, anon, authenticated, service_role;

create or replace function private.run_retention_cleanup(
  p_now timestamptz default clock_timestamp()
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rate_windows integer := 0;
  v_cached_products integer := 0;
  v_idempotency_keys integer := 0;
  v_audit_records integer := 0;
  v_daily_usage integer := 0;
  v_cron_history integer := 0;
  v_health_checks integer := 0;
  v_resolved_alerts integer := 0;
begin
  if p_now > clock_timestamp() + interval '5 minutes' then
    raise exception 'cleanup clock cannot be in the future'
      using errcode = '22023';
  end if;

  delete from private.writer_rate_windows
  where ctid in (
    select ctid from private.writer_rate_windows
    where window_started_at < p_now - interval '1 hour'
    order by window_started_at limit 10000
  );
  get diagnostics v_rate_windows = row_count;

  delete from public.cached_products
  where ctid in (
    select ctid from public.cached_products
    where expires_at < p_now - interval '1 day'
    order by expires_at limit 10000
  );
  get diagnostics v_cached_products = row_count;

  delete from private.writer_idempotency_keys
  where ctid in (
    select ctid from private.writer_idempotency_keys
    where created_at < p_now - interval '30 days'
    order by created_at limit 10000
  );
  get diagnostics v_idempotency_keys = row_count;

  perform set_config('scanfair.audit_retention_cleanup', 'enabled', true);
  delete from private.writer_audit_log
  where ctid in (
    select ctid from private.writer_audit_log
    where created_at < p_now - interval '90 days'
    order by created_at limit 10000
  );
  get diagnostics v_audit_records = row_count;
  perform set_config('scanfair.audit_retention_cleanup', 'disabled', true);

  delete from private.writer_daily_usage
  where usage_date < (p_now at time zone 'UTC')::date - 400;
  get diagnostics v_daily_usage = row_count;

  delete from cron.job_run_details
  where runid in (
    select runid from cron.job_run_details
    where end_time < p_now - interval '30 days'
    order by end_time limit 10000
  );
  get diagnostics v_cron_history = row_count;

  delete from private.retention_health_checks
  where check_id in (
    select check_id from private.retention_health_checks
    where checked_at < p_now - interval '90 days'
    order by checked_at limit 10000
  );
  get diagnostics v_health_checks = row_count;

  delete from private.retention_alert_outbox
  where alert_id in (
    select alert_id from private.retention_alert_outbox
    where lifecycle_status = 'resolved'
      and resolved_at < p_now - interval '400 days'
    order by resolved_at limit 10000
  );
  get diagnostics v_resolved_alerts = row_count;

  return jsonb_build_object(
    'rate_windows_deleted', v_rate_windows,
    'cached_products_deleted', v_cached_products,
    'idempotency_keys_deleted', v_idempotency_keys,
    'audit_records_deleted', v_audit_records,
    'daily_usage_deleted', v_daily_usage,
    'cron_history_deleted', v_cron_history,
    'retention_health_checks_deleted', v_health_checks,
    'resolved_retention_alerts_deleted', v_resolved_alerts
  );
end;
$$;

revoke all on function private.run_retention_cleanup(timestamptz)
  from public, anon, authenticated, service_role;

select cron.unschedule(jobid)
from cron.job
where jobname = 'scanfair-retention-health-monitor';

select cron.schedule(
  'scanfair-retention-health-monitor',
  '30 3 * * *',
  'select private.record_retention_health();'
);
