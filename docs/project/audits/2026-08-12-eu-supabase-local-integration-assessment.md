# EU Supabase Local Integration Assessment

- Date: 2026-08-12
- Scope: NEXT-05 local trusted-writer, database and read-only Flutter path
- Environment: disposable local Supabase stack with public-source test data
- Decision: PASS for local implementation; remote activation remains blocked

## Implemented path

The mobile app can use only a publishable key and the bounded
`get_fresh_cached_product` RPC. It has no direct cache-table access and cannot
invoke any writer RPC. Cache miss, stale data, connectivity failure and server
failure fall back to direct Open Food Facts lookup.

The Edge Function accepts only two named server actors, each with a separate
runtime secret. It rejects unknown input fields and runtime URLs, fetches only
the fixed HTTPS Open Food Facts host, validates response size and schema, and
uses bounded retry pacing. Server-only database functions enforce rate and
daily budgets, a persisted circuit breaker, deterministic idempotency,
out-of-order rejection, OFF license partitioning and append-only redacted
audit evidence.

## Validation evidence

| Check | Result |
|---|---:|
| Writer contract tests | 12/12 PASS |
| Automated Edge auth/schema smoke | 3/3 PASS |
| Backend-boundary self-tests | 16/16 PASS |
| Supabase migration replay | PASS |
| pgTAP database and writer tests | 123/123 PASS |
| PostgreSQL lint | PASS, 0 schema errors |
| Flutter cache and fallback tests | 15/15 PASS |
| Full Flutter suite | 101/101 PASS |
| Flutter line coverage | 84.26% |
| Development quality gates | 29/29 PASS |

The actual local Edge Runtime used Deno 2.1.4. The wrapper rejected an invalid
secret with HTTP 401 and an unknown URL field with HTTP 400. A controlled OFF
product was published through the server-only RPC, returned publication status
201, returned `duplicate_existing` on replay and was readable as exactly one
fresh row through the public read RPC. No runtime secret or full response body
is retained in this evidence document.

## Pull request review follow-up

PR 22 identified two defects before merge. An unchanged OFF payload now keeps
one idempotency record while advancing only matching cache freshness fields.
Publication/database failures are audited as `database_rejected` or
`database_unavailable`, while only OFF failures use `upstream_*` outcomes.
Unknown internal failures use `writer_internal_error`.

The follow-up passed 12/12 writer-contract tests, 123/123 pgTAP tests,
migration replay, database lint, the local Edge integration gate and the full
29/29 development gate pipeline.

## Remaining activation blockers

- The Frankfurt development project is provisioned and locally linked, but no
  remote schema, Edge Function or app access has been deployed or activated.
- DPA and subprocessor owner approvals remain pending.
- Independent writer-security and operational-readiness reviews are pending.
- Secret rotation, break-glass and incident drills are not yet evidenced.
- Remote migration/RLS integration, monitoring and cost alerts are pending.
- Privacy and ODbL remote-activation profiles remain intentionally blocked.

This assessment is implementation evidence, not production approval, a
penetration test or an App Store release decision.
