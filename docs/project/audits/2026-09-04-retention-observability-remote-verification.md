# Retention-Observability Remote Verification

- Verified: 2026-09-04 UTC
- Environment: `scanfair-dev`
- Region: `eu-central-1` (Frankfurt)
- Scope: Migration 13, scheduled health monitoring and controlled alert-lifecycle verification
- Runtime and app access: disabled

## Method

The linked Supabase migration inventory, `pg_cron` job definitions and recent
job history were read without changing application data. The controlled
verifier `scripts/quality/verify_remote_retention_observability.sql` was then
executed against the linked development database. Its failure/recovery fixture
runs in a nested transaction and deliberately rolls itself back.

## Verified Remote State

| Control | Result |
|---|---|
| Migration `20260820000100_retention_observability.sql` | Applied remotely; all 13 migrations reconciled |
| Cleanup job | Active as `postgres`: `20 3 * * *`, `select private.run_retention_cleanup();` |
| Health-monitor job | Active as `postgres`: `30 3 * * *`, `select private.record_retention_health();` |
| Real monitor history | Four successful daily executions on 2026-09-01 through 2026-09-04 at 03:30 UTC |
| Controlled failure/recovery verifier | Passed; a critical alert was created for the simulated failure and resolved after simulated recovery |
| Retained verifier rows | `0` health fixtures and `0` alert fixtures after rollback |

This is operational evidence for the private database-side detection,
deduplication and recovery lifecycle. It is not evidence of an external
operator notification.

## Remaining Activation Boundary

`private.retention_alert_outbox` remains intentionally private and external
delivery is still `not_configured_runtime_disabled`. No delivery owner,
least-privilege notification identity, approved secret lifecycle or delivery
channel has been selected. Consequently no real failure/recovery notification
could be received and no delivery-failure negative test exists.

Remote backend and release-candidate profiles remain blocked until those
operational decisions and their evidence are completed. This review does not
enable runtime, app access, accounts or personal-data processing.

## Related Evidence

- `supabase/migrations/20260820000100_retention_observability.sql`
- `supabase/tests/database/retention_observability.test.sql`
- `scripts/quality/verify_remote_retention_observability.sql`
- `docs/project/security/retention-observability-contract.yaml`
- `docs/project/decisions/0038-retention-observability-and-alert-delivery.yaml`
