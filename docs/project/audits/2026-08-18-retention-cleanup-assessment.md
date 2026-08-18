# Retention and Cleanup Assessment

- Date: 2026-08-18
- Branch: `feature/retention-cleanup`
- Scope: TODO-037 retention and cleanup; remote runtime remains disabled
- Excluded: public read-rate limiting, personal access logs, accounts and release activation

## Decision

ADR 0037 defines explicit retention for the technical writer data path. A
single daily pg_cron job invokes a private cleanup function at 03:20 UTC.
Large-table deletes are limited to 10,000 rows per run. The function cannot be
executed by mobile roles or `service_role`.

| Data class | Retention boundary | Reason |
|---|---:|---|
| Writer rate windows | 1 hour | Minute-level abuse counters have no later purpose. |
| Expired product cache | 1 day after expiry | Short recovery margin without retaining stale payloads indefinitely. |
| Idempotency events | 30 days | Operational replay diagnosis. |
| Writer audit | 90 days | Development incident investigation and accountability. |
| Daily writer usage | 400 days | Annual capacity and cost trend with a small aggregate footprint. |
| pg_cron run history | 30 days | Job diagnosis without unbounded extension history. |
| Source-record watermark | Source-record lifecycle | Minimum durable integrity state for ordering and conflict rejection. |

## Findings And Controls

| ID | Severity | Finding | Disposition |
|---|---|---|---|
| RET-01 | High | Cleanup of idempotency/cache rows could allow old source data to be republished. | Closed locally and remotely by a private hash-bound watermark and replay tests. |
| RET-02 | High | Append-only audit prevented the required retention deletion. | Closed locally and remotely by a narrowly owner-gated cleanup path; direct deletion remains blocked. |
| RET-03 | Medium | Cleanup could create long locks at scale. | Bounded to 10,000 rows; partition review has measurable triggers in ADR 0037. |
| RET-04 | Medium | pg_cron history can itself grow without cleanup. | Included in the same 30-day bounded cleanup. |
| RET-05 | High | A technical retention decision could be mistaken for personal-data approval. | Remote runtime and personal logs remain prohibited; privacy activation stays fail-closed. |
| RET-06 | Medium | Scheduled cleanup can silently stop after deployment or upgrade. | Remote job identity and a controlled cleanup drill are verified; first scheduled-run observation, failure alert and backlog monitor remain required. |
| RET-07 | High | A future writer clock could extend cache expiry beyond the intended retention boundary. | Closed locally and remotely by a five-minute future-clock cap and negative tests. |

## Verification

- 12 forward-only migrations replayed locally.
- 213/213 pgTAP assertions passed across seven test files after cache-repair and future-clock hardening.
- PostgreSQL lint passed with no schema errors.
- Cron database, owner, schedule and private command were verified locally.
- Older, conflicting and exact replay paths were exercised after cleanup.
- The Edge-writer integration gate and all 12 writer-contract tests passed.
- The complete local development pipeline passed 29/29 gates; remote-backend
  and release-candidate profiles remained fail-closed on their required reviews.
- Pull request 28 and post-merge `main` completed all six GitHub Actions jobs
  in runs `32173551869` and `32173898928`.
- All 12 migrations are registered on `scanfair-dev`; linked dry-run reports
  no pending migration, linked lint has no finding and the `public`/`private`
  schema diff is empty.
- Hosted `pg_cron` 1.6.4 is installed with exactly one active
  `scanfair-retention-cleanup` job at `20 3 * * *`, owned and executed by
  `postgres` in database `postgres`.
- `scripts/quality/verify_remote_retention_cleanup.sql` passed the controlled
  remote cleanup, authorization, clock, boundary and replay tests in a
  rollback subtransaction. It retained zero cache, watermark, audit or cron
  fixtures.
- The existing remote backend readiness verifier also passed and retained no
  fixtures.

## Remaining Boundary

The schema and controlled cleanup drill are remote deployment evidence, but
they are not runtime approval. App and writer runtime remain disabled. Before
activation, the first real scheduled execution must be observed and cleanup
failure alerting plus eligible-backlog monitoring must be operationally
verified. Public read-rate limiting and abuse-negative tests also remain open
under TODO-037 and RISK-015.
