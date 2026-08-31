do $verification$
declare
  v_cleanup_job_count integer;
  v_monitor_job_count integer;
  v_cleanup_job_id bigint;
  v_now timestamptz := pg_catalog.clock_timestamp();
  v_status text;
begin
  select count(*), min(jobid)
  into v_cleanup_job_count, v_cleanup_job_id
  from cron.job
  where jobname = 'scanfair-retention-cleanup'
    and active
    and schedule = '20 3 * * *'
    and command = 'select private.run_retention_cleanup();'
    and database = 'postgres'
    and username = 'postgres';

  select count(*) into v_monitor_job_count
  from cron.job
  where jobname = 'scanfair-retention-health-monitor'
    and active
    and schedule = '30 3 * * *'
    and command = 'select private.record_retention_health();'
    and database = 'postgres'
    and username = 'postgres';

  if v_cleanup_job_count <> 1 or v_monitor_job_count <> 1 then
    raise exception 'retention cron identity verification failed: cleanup %, monitor %',
      v_cleanup_job_count, v_monitor_job_count;
  end if;

  if pg_catalog.has_table_privilege(
       'service_role', 'private.retention_health_checks', 'select'
     ) or pg_catalog.has_table_privilege(
       'service_role', 'private.retention_alert_outbox', 'select'
     ) or pg_catalog.has_function_privilege(
       'service_role',
       'private.retention_health_snapshot(timestamptz)',
       'execute'
     ) or pg_catalog.has_function_privilege(
       'service_role',
       'private.record_retention_health(timestamptz)',
       'execute'
     ) then
    raise exception 'service_role unexpectedly has retention observability access';
  end if;

  begin
    insert into cron.job_run_details (
      jobid, runid, database, username, command, status, return_message,
      start_time, end_time
    ) values (
      v_cleanup_job_id, -9501, 'postgres', 'postgres',
      'select private.run_retention_cleanup();', 'failed',
      'scanfair-retention-observability-verifier',
      v_now - interval '1 minute', v_now
    );

    select private.record_retention_health(v_now) ->> 'health_status'
    into v_status;
    if v_status <> 'critical' then
      raise exception 'controlled failure was not detected: %', v_status;
    end if;

    if not exists (
      select 1 from private.retention_alert_outbox
      where alert_code = 'cleanup_latest_run_failed'
        and lifecycle_status = 'open'
    ) then
      raise exception 'controlled failure did not open an alert';
    end if;

    insert into cron.job_run_details (
      jobid, runid, database, username, command, status, return_message,
      start_time, end_time
    ) values (
      v_cleanup_job_id, -9502, 'postgres', 'postgres',
      'select private.run_retention_cleanup();', 'succeeded',
      'scanfair-retention-observability-verifier-recovery',
      v_now + interval '1 second', v_now + interval '2 seconds'
    );

    select private.record_retention_health(v_now + interval '3 seconds')
      ->> 'health_status'
    into v_status;
    if v_status = 'critical' then
      raise exception 'controlled recovery remained critical';
    end if;

    if exists (
      select 1 from private.retention_alert_outbox
      where alert_code = 'cleanup_latest_run_failed'
        and lifecycle_status = 'open'
    ) then
      raise exception 'controlled recovery did not resolve the alert';
    end if;

    raise exception 'SCANFAIR_RETENTION_OBSERVABILITY_VERIFICATION_ROLLBACK';
  exception
    when raise_exception then
      if sqlerrm <> 'SCANFAIR_RETENTION_OBSERVABILITY_VERIFICATION_ROLLBACK' then
        raise;
      end if;
  end;

  if exists (
    select 1 from cron.job_run_details where runid in (-9501, -9502)
  ) or exists (
    select 1 from private.retention_health_checks
    where checked_at >= v_now
  ) or exists (
    select 1 from private.retention_alert_outbox
    where payload ->> 'checked_at' >= v_now::text
  ) then
    raise exception 'retention observability verification fixtures were retained';
  end if;
end
$verification$;
