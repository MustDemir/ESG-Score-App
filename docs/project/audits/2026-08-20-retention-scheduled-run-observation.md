# Retention Scheduled-Run Observation

- Observed: 2026-08-20 at 07:14 UTC
- Environment: `scanfair-dev`
- Region: `eu-central-1` (Frankfurt)
- Runtime and app access: disabled
- Query type: read-only linked database observation

## Scheduled Runs

The deployed `scanfair-retention-cleanup` job remained active with the exact
schedule `20 3 * * *`, command `select private.run_retention_cleanup();`,
database `postgres` and role `postgres`.

| Run ID | Started UTC | Ended UTC | Status | Result |
|---:|---|---|---|---|
| 1 | 2026-08-19 03:20:00.288 | 2026-08-19 03:20:00.386 | succeeded | 1 row |
| 2 | 2026-08-20 03:20:00.244 | 2026-08-20 03:20:00.341 | succeeded | 1 row |

Both real scheduled executions completed in under one second. This closes the
first-scheduled-run observation required by ADR 0037; it does not approve app
or writer runtime.

## Backlog And Runtime Boundary

At the observation time, eligible backlog counts were zero for writer rate
windows, expired cache, idempotency events, writer audit, daily usage and old
cron history. Runtime row counts were also zero for cached products, writer
audit, rate windows and idempotency events.

## Remaining Boundary

A successful run history is not an alerting system. Migration 13 and ADR 0038
therefore introduce private health history and an alert outbox. External alert
delivery is intentionally not configured on the Free Plan and remains a
remote-activation blocker until a least-privilege channel, cost/provider review
and controlled failure-and-recovery notification drill exist.
