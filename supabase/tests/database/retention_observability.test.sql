begin;

create extension if not exists pgtap with schema extensions;

select plan(37);

select has_table(
  'private', 'retention_health_checks',
  'private retention health history exists'
);
select has_table(
  'private', 'retention_alert_outbox',
  'private retention alert outbox exists'
);
select ok(
  (select relrowsecurity from pg_catalog.pg_class
   where oid = 'private.retention_health_checks'::regclass),
  'retention health history has RLS enabled'
);
select ok(
  (select relrowsecurity from pg_catalog.pg_class
   where oid = 'private.retention_alert_outbox'::regclass),
  'retention alert outbox has RLS enabled'
);
select is(
  has_table_privilege('service_role', 'private.retention_health_checks', 'SELECT'),
  false,
  'service_role cannot read retention health history'
);
select is(
  has_table_privilege('service_role', 'private.retention_alert_outbox', 'SELECT'),
  false,
  'service_role cannot read retention alert outbox'
);
select has_function(
  'private', 'retention_health_snapshot', array['timestamp with time zone'],
  'private retention health snapshot exists'
);
select has_function(
  'private', 'record_retention_health', array['timestamp with time zone'],
  'private retention health recorder exists'
);
select is(
  has_function_privilege(
    'service_role', 'private.retention_health_snapshot(timestamptz)', 'EXECUTE'
  ),
  false,
  'service_role cannot evaluate retention health'
);
select is(
  has_function_privilege(
    'service_role', 'private.record_retention_health(timestamptz)', 'EXECUTE'
  ),
  false,
  'service_role cannot record retention health'
);
select is(
  (select count(*)::integer from cron.job
   where jobname = 'scanfair-retention-health-monitor'),
  1,
  'exactly one retention health monitor job exists'
);
select is(
  (select database || ':' || username || ':' || schedule || ':' || command
   from cron.job where jobname = 'scanfair-retention-health-monitor'),
  'postgres:postgres:30 3 * * *:select private.record_retention_health();',
  'retention health monitor runs as postgres daily at 03:30 UTC'
);

create temporary table retention_health_clock as
select clock_timestamp() as now;

insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time
) values (
  (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
  -9401, current_database(), current_user, 'health-success', 'succeeded',
  (select now - interval '1 hour' from retention_health_clock),
  (select now - interval '1 hour' + interval '100 milliseconds'
   from retention_health_clock)
);

select is(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) ->> 'health_status',
  'healthy',
  'recent successful cleanup with no backlog is healthy'
);
select is(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) #>> '{eligible_backlog,writer_rate_windows}',
  '0',
  'healthy snapshot records the empty eligible backlog'
);
select lives_ok(
  $$ select private.record_retention_health(
       (select now from retention_health_clock)
     ) $$,
  'healthy retention observation is recorded'
);
select is(
  (select count(*)::integer from private.retention_health_checks
   where health_status = 'healthy'),
  1,
  'healthy observation creates one health-history row'
);
select is(
  (select count(*)::integer from private.retention_alert_outbox),
  0,
  'healthy observation creates no alert'
);

insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time,
  return_message
) values (
  (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
  -9402, current_database(), current_user, 'health-failure', 'failed',
  (select now - interval '30 minutes' from retention_health_clock),
  (select now - interval '29 minutes' from retention_health_clock),
  'controlled test failure'
);

select is(
  private.record_retention_health(
    (select now from retention_health_clock)
  ) ->> 'health_status',
  'critical',
  'latest failed cleanup creates a critical health result'
);
select ok(
  (select breach_codes @> array['cleanup_latest_run_failed']
   from private.retention_health_checks
   order by check_id desc limit 1),
  'failed cleanup is represented by a stable breach code'
);
select is(
  (select count(*)::integer from private.retention_alert_outbox
   where alert_code = 'cleanup_latest_run_failed'
     and lifecycle_status = 'open'),
  1,
  'failed cleanup opens exactly one alert'
);
select is(
  (select delivery_status from private.retention_alert_outbox
   where alert_code = 'cleanup_latest_run_failed'
     and lifecycle_status = 'open'),
  'not_configured_runtime_disabled',
  'development alert records that outbound delivery is not configured'
);

select lives_ok(
  $$ select private.record_retention_health(
       (select now from retention_health_clock)
     ) $$,
  'repeated failure evaluation is accepted'
);
select is(
  (select occurrence_count from private.retention_alert_outbox
   where alert_code = 'cleanup_latest_run_failed'
     and lifecycle_status = 'open'),
  2,
  'repeated failure deduplicates and increments the alert occurrence count'
);

insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time
) values (
  (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
  -9403, current_database(), current_user, 'health-recovery', 'succeeded',
  (select now - interval '10 minutes' from retention_health_clock),
  (select now - interval '9 minutes' from retention_health_clock)
);

select is(
  private.record_retention_health(
    (select now from retention_health_clock)
  ) ->> 'health_status',
  'healthy',
  'new successful cleanup restores healthy state'
);
select is(
  (select lifecycle_status from private.retention_alert_outbox
   where alert_code = 'cleanup_latest_run_failed'),
  'resolved',
  'recovery resolves the open cleanup-failure alert'
);
select is(
  (select count(*)::integer from private.retention_alert_outbox
   where lifecycle_status = 'open'),
  0,
  'recovery leaves no open alert'
);

delete from cron.job_run_details where runid between -9499 and -9400;
insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time
) values (
  (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
  -9410, current_database(), current_user, 'health-stale', 'succeeded',
  (select now - interval '38 hours' from retention_health_clock),
  (select now - interval '37 hours' from retention_health_clock)
);

select is(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) ->> 'health_status',
  'critical',
  'cleanup success older than thirty-six hours is critical'
);
select ok(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) -> 'breach_codes' ? 'cleanup_success_stale',
  'stale cleanup success has a stable breach code'
);

do $test$
declare
  v_jobid bigint;
begin
  select jobid into v_jobid
  from cron.job
  where jobname = 'scanfair-retention-cleanup';
  perform cron.unschedule(v_jobid);
end
$test$;
select ok(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) -> 'breach_codes' ? 'cleanup_job_configuration_invalid',
  'inactive cleanup job is a configuration breach'
);
do $test$
begin
  perform cron.schedule(
    'scanfair-retention-cleanup',
    '20 3 * * *',
    'select private.run_retention_cleanup();'
  );
end
$test$;

delete from cron.job_run_details where runid = -9410;
insert into cron.job_run_details (
  jobid, runid, database, username, command, status, start_time, end_time
)
select
  (select jobid from cron.job where jobname = 'scanfair-retention-cleanup'),
  -9420 - offset_value,
  current_database(),
  current_user,
  'health-slow-' || offset_value,
  'succeeded',
  (select now - (offset_value || ' hours')::interval
   from retention_health_clock),
  (select now - (offset_value || ' hours')::interval + interval '3 seconds'
   from retention_health_clock)
from generate_series(1, 3) as offsets(offset_value);

select ok(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) -> 'breach_codes' ? 'cleanup_duration_partition_review',
  'three slow cleanup runs trigger a partition review warning'
);

insert into private.writer_rate_windows (
  scope, actor_type, window_started_at, request_count
)
select
  'health-backlog',
  'health-actor-' || item,
  (select now - interval '2 hours' from retention_health_clock),
  1
from generate_series(1, 10000) as items(item);

select is(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) ->> 'health_status',
  'warning',
  'one cleanup batch of eligible backlog creates a warning'
);
select ok(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) -> 'breach_codes' ? 'cleanup_backlog_at_or_above_batch',
  'batch-sized backlog has a stable warning code'
);

delete from private.retention_health_checks;
insert into private.retention_health_checks (
  checked_at, health_status, eligible_backlog, total_writer_audit_rows,
  breach_codes, details
)
select
  (select now - (item || ' days')::interval from retention_health_clock),
  'warning',
  '{"writer_rate_windows":10000,"cached_products":0,"writer_idempotency_keys":0,"writer_audit_log":0,"writer_daily_usage":0,"cron_job_run_details":0}'::jsonb,
  0,
  array['cleanup_backlog_at_or_above_batch'],
  '{}'::jsonb
from generate_series(1, 6) as days(item);

select ok(
  private.retention_health_snapshot(
    (select now from retention_health_clock)
  ) -> 'breach_codes' ? 'cleanup_backlog_persistent_seven_checks',
  'seventh consecutive batch-sized backlog check becomes critical'
);

insert into private.retention_health_checks (
  checked_at, health_status, eligible_backlog, total_writer_audit_rows,
  breach_codes, details
) values (
  (select now - interval '91 days' from retention_health_clock),
  'healthy', '{}'::jsonb, 0, '{}', '{}'::jsonb
);
insert into private.retention_alert_outbox (
  alert_code, severity, lifecycle_status, delivery_status,
  first_detected_at, last_detected_at, resolved_at, payload
) values (
  'resolved-old-alert', 'warning', 'resolved',
  'not_configured_runtime_disabled',
  (select now - interval '401 days' from retention_health_clock),
  (select now - interval '401 days' from retention_health_clock),
  (select now - interval '401 days' from retention_health_clock),
  '{}'::jsonb
);

create temporary table retention_observability_cleanup as
select private.run_retention_cleanup(
  (select now from retention_health_clock)
) as value;

select is(
  (select (value ->> 'retention_health_checks_deleted')::integer
   from retention_observability_cleanup),
  1,
  'cleanup expires retention health checks after ninety days'
);
select is(
  (select (value ->> 'resolved_retention_alerts_deleted')::integer
   from retention_observability_cleanup),
  1,
  'cleanup expires resolved retention alerts after four hundred days'
);
select ok(
  (select count(*) > 0 from private.retention_health_checks),
  'cleanup retains recent retention health checks'
);

select throws_ok(
  $$ select private.retention_health_snapshot(clock_timestamp() + interval '1 day') $$,
  '22023',
  'retention health clock cannot be in the future',
  'retention health evaluation rejects a future caller clock'
);

select * from finish();

rollback;
