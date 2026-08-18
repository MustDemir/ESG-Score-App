# Remote Deployment Verification

## Scope

- Date: 2026-08-18
- Repository baseline: merge commit `cd64718`
- Environment: linked Supabase development project `scanfair-dev`
- Region: `eu-central-1` (Frankfurt)
- Runtime activation: explicitly excluded
- Personal data: explicitly prohibited
- Credentials and project identifiers: not recorded

## Deployment Observation

Pull Request 24 passed all six GitHub Actions jobs and was merged into `main`.
Before any non-dry-run database push was issued in this session, the linked
migration history already contained migration `20260817000100`. A repeated
dry run then reported the database as up to date. Repository workflow and
script searches found no automatic linked deployment command.

This report therefore records the observed remote state without claiming an
unobserved deployment actor. No `supabase db push` without `--dry-run` was run
for migration 10 during this session.

## Verification Results

1. Linked DB lint returned no schema errors.
2. The bounded evidence and score RPCs exist as `SECURITY DEFINER` functions.
3. `anon` and `authenticated` have no direct evidence/snapshot table reads.
4. Published barcode-scoped rows are returned; drafts, unrelated states and an
   invalid barcode are not returned.
5. `partial_score` is accepted by the deployed score-state constraint.
6. The transactional verifier rolled back all fixtures; follow-up counts were
   zero for both evidence and snapshot fixtures.
7. Linked schema diff showed only provider-default `service_role` grants on
   application tables. No function, constraint, policy or structural drift was
   observed.

## Hosted pgTAP Limitation

`supabase test db --linked` cannot reproduce the local pgTAP suite because the
hosted project does not expose an installed pgTAP extension or its `plan()`
function. The CLI produced an inconsistent extension message, while a catalog
query confirmed that pgTAP is absent. This limitation is not reported as a
passing remote pgTAP run.

The remote behavior was instead checked with a fail-fast transactional SQL
verifier. The verifier is now versioned at
`scripts/quality/verify_remote_backend_readiness.sql`. The complete 180-test
pgTAP suite remains reproducible against the local Supabase stack.

## Finding RDV-01: Broad service_role Grants

- Severity: high before writer activation
- Status: remediation locally validated; remote application pending
- Risk: direct table writes could bypass validation, idempotency, ordering,
  publication and append-only audit controls
- Decision: ADR 0036 requires RPC-only least privilege
- Remediation: forward-only migration
  `20260818000100_service_role_least_privilege.sql`
- Tests: 8 new pgTAP assertions, 180/180 total, DB lint and Edge writer
  integration gate pass locally

The mobile backend and trusted writer remain disabled. Migration 11 must pass
normal pull-request review and GitHub Actions before controlled remote
application. After deployment, the versioned remote verifier must prove that
all direct service-role table/sequence privileges are absent and the four
bounded writer RPCs remain executable.

## Remaining Boundaries

- Runtime, mobile app access and accounts remain disabled.
- DPA and subprocessor owner approval remain pending.
- Retention/cleanup and public read-rate limiting remain open in TODO-037.
- Staging, production, TestFlight and App Store release are not authorized.
