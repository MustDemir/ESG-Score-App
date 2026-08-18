# Remote Schema State Assessment

## Scope

- Date: 2026-08-17
- Environment: linked Supabase development project `scanfair-dev`
- Region: `eu-central-1` (Frankfurt)
- Runtime activation: explicitly excluded
- Personal data: explicitly prohibited
- Credentials and project identifiers: not recorded in this report

## Method

The linked environment was inspected with the Supabase CLI. No migration,
function or application configuration was deployed during the assessment.

```text
supabase migration list
supabase db diff --linked --schema public,private
supabase db lint --linked --level warning
supabase inspect db table-stats --linked
```

## Results

1. All nine repository migrations through `20260813000200` are registered in
   both local and linked migration history.
2. The linked schema diff reported no schema changes.
3. The linked DB lint reported no schema errors.
4. Runtime tables are empty: cache, evidence, snapshots, scans, relationships
   and private writer tables contain no records.
5. Only non-personal seed metadata is present: three data-source rows and two
   methodology-version rows were estimated by table statistics.
6. No mobile app access, trusted writer, account flow or personal-data path is
   enabled by this state.

## Corrected Assessment

The earlier SSOT phrase "remote schema not deployed" is inaccurate. The
correct state is:

```text
remote schema deployed and reconciled
remote runtime disabled
remote app access disabled
remote writer disabled
personal data prohibited
```

Schema presence is not provider approval, GDPR approval, operational readiness
or release approval. Those controls remain fail-closed in their dedicated
profiles.

## Remediation Decision

Historical migrations remain immutable. ADR 0035 requires a forward-only
migration for direct-read revocation, bounded evidence/snapshot RPCs and
`partial_score` persistence. That migration is locally validated first and is
not part of this remote assessment.

Retention, scheduled cleanup and public read-rate limiting remain open until
privacy, operations and abuse-risk requirements are reviewed. No arbitrary
retention period is introduced.
