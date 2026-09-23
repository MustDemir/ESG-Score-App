# Public-Read Abuse Protection Validation

- Remote transient validation: 2026-09-06 UTC
- Local replay validation: 2026-09-07 UTC
- Environment used for transient verification: `scanfair-dev`, `eu-central-1`
- Runtime and app access: disabled throughout
- Scope: Migration 14's PostgREST pre-request control, private counter boundary and cleanup configuration

## Method And Boundary

Migration `20260906000100_public_read_abuse_protection.sql` and its controlled
verifier were executed together in one database-service transaction. The
verifier exercised the migration before its enclosing rollback. A subsequent
read-only inspection confirmed that the rate-window table, authenticator hook
and cleanup cron job were all absent afterwards. Migration 14 therefore remains
**not applied** to the remote development schema.

On 7 September the pre-reset local schema and data were backed up under
`/private/tmp/esg-score-app-local-backup-20260907`. The local Supabase database
was then rebuilt from the versioned migration chain. All 14 migrations,
including migration 14, replayed successfully. The complete database suite
passed 277/277 assertions, including all 27 public-read abuse assertions, and
database lint reported no schema errors.

## Transient Verification Results

| Control | Result |
|---|---|
| Private rate-window table and privilege boundary | Passed during rollback-only execution |
| `authenticator` pre-request hook | Configured and detected during rollback-only execution |
| postgres-owned five-minute cleanup job | Exact identity, schedule and command verified |
| Protected RPC behavior | 30 requests in one IP-minute admitted atomically; the 31st rejected with the expected `PGRST` rate-limit payload |
| Bypass resistance | GET on a protected RPC rejected; missing client identity rejected |
| Fixture persistence | No rows, hook or cron job remained after rollback |

## Local Replay Results

| Control | Result |
|---|---|
| Versioned migration replay | 14/14 migrations replayed |
| Public-read abuse pgTAP | 27/27 passed |
| Complete database pgTAP | 277/277 passed |
| Database lint | Passed with no schema errors |
| Development quality gates | 33/33 passed |

## Remaining Activation Boundary

Before applying migration 14 to `scanfair-dev` or routing app traffic through
the remote API, obtain the required privacy decision for pseudonymous security
telemetry. Then apply the reviewed migration and run this linked verifier again.
The existing external retention-alert delivery decision remains a separate
TODO-037 blocker.

## Related Artifacts

- `supabase/migrations/20260906000100_public_read_abuse_protection.sql`
- `supabase/tests/database/public_read_abuse_protection.test.sql`
- `scripts/quality/verify_public_read_abuse_protection.sql`
- `docs/project/decisions/0040-public-read-abuse-protection.yaml`
