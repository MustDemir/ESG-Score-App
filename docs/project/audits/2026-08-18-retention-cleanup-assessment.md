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
| RET-01 | High | Cleanup of idempotency/cache rows could allow old source data to be republished. | Closed locally by a private hash-bound watermark and replay tests. |
| RET-02 | High | Append-only audit prevented the required retention deletion. | Closed locally by a narrowly owner-gated cleanup path; direct deletion remains blocked. |
| RET-03 | Medium | Cleanup could create long locks at scale. | Bounded to 10,000 rows; partition review has measurable triggers in ADR 0037. |
| RET-04 | Medium | pg_cron history can itself grow without cleanup. | Included in the same 30-day bounded cleanup. |
| RET-05 | High | A technical retention decision could be mistaken for personal-data approval. | Remote runtime and personal logs remain prohibited; privacy activation stays fail-closed. |
| RET-06 | Medium | Scheduled cleanup can silently stop after deployment or upgrade. | Local job identity/schedule is tested; remote job and monitoring evidence remain required. |
| RET-07 | High | A future writer clock could extend cache expiry beyond the intended retention boundary. | Closed locally by a five-minute future-clock cap and a negative pgTAP assertion. |

## Verification

- 12 forward-only migrations replayed locally.
- 213/213 pgTAP assertions passed across seven test files after cache-repair and future-clock hardening.
- PostgreSQL lint passed with no schema errors.
- Cron database, owner, schedule and private command were verified locally.
- Older, conflicting and exact replay paths were exercised after cleanup.
- The Edge-writer integration gate and all 12 writer-contract tests passed.
- The complete local development pipeline passed 29/29 gates; remote-backend
  and release-candidate profiles remained fail-closed on their required reviews.
- Linked migration listing and dry run showed exactly migration 12 pending.
  Hosted `pg_cron` 1.6.4 is available but remains uninstalled; no remote write
  was performed.

## Remaining Boundary

This assessment is local implementation evidence, not remote deployment or
runtime approval. Migration 12 must pass pull-request CI before controlled
application to `scanfair-dev`. Public read-rate limiting and abuse-negative
tests remain open under TODO-037 and RISK-015.
