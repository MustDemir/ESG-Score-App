# ScanFair local Supabase schema

This directory prepares the local, migration-based database layer. It is not
linked to a remote project and contains no credentials.

## Local validation

Prerequisites: Docker Desktop, Supabase CLI 2.110.0 and Node.js 22 or newer.

```bash
supabase start
supabase db reset --local
supabase test db --local
supabase db lint --local --level warning
supabase stop

node --test supabase/functions/_shared/writer_contract.test.mjs
bash scripts/quality/run_edge_writer_integration_gate.sh
```

`db reset --local` recreates the local database and applies every migration.
Do not run `db reset --linked` against a non-disposable remote project.
The 119-test pgTAP suite verifies table structure, RLS activation, fact,
methodology and traceability write denial, relationship eligibility
constraints, draft-method visibility, owner-only scan behavior and the OFF
license-partition boundary. It also verifies writer authorization, bounded
reads, rate and daily budgets, idempotency, out-of-order rejection,
circuit-breaker behavior and append-only audit.

Without Docker, the static gates remain available:

```bash
ruby scripts/quality/validate_data_architecture.rb
ruby scripts/quality/validate_data_license_composition.rb --profile development
ruby scripts/quality/validate_methodology_catalog.rb
ruby scripts/quality/validate_scoring_safety.rb --gate link-integrity
```

The read-only Flutter cache adapter and the trusted server writer now exist.
They remain disabled at runtime because no remote project configuration is
supplied. The app therefore continues to read Open Food Facts directly. Once
approved remote configuration exists, the lookup order is fresh Supabase
cache, direct Open Food Facts and then the existing transparent no-data state.
Stale cache rows are rejected both by the database and by Flutter.

The definition-of-ready for that increment is versioned in
`docs/project/security/backend-threat-model.yaml` and
`docs/project/security/eu-supabase-environment-contract.yaml`. Run
`ruby scripts/quality/validate_backend_boundary.rb --profile development`
before changing the remote data path. `G-BACKEND-BOUNDARY` executes the writer
contract tests and deliberately fails remote activation without typed,
SHA-256-bound environment, independent writer-security and operational-
readiness evidence.

## Security model

- All public tables have RLS enabled and forced.
- ESG source data is client-readable only through bounded read contracts and
  remains server-maintained.
- `cached_products` has no direct client `SELECT`; a fresh, single-barcode RPC
  returns an explicit column set.
- Upstream evidence can retain a separate `retrieved_via_source_id`.
- Traceability entities, identifiers and relationships are server-maintained.
- Low-confidence, inferred and community relationships cannot be score-eligible.
- Score snapshots retain relationship and red-flag lineage separately.
- Only published methodology is client-readable; catalog writes are server-only.
- Authenticated users can only read, create and delete their own scan rows.
- No service-role key is permitted in Flutter code.
- A mobile client cannot invoke the trusted writer; only named server-side
  jobs and audited operator replay may do so.
- The writer uses fixed HTTPS upstream targets, strict request and response
  bounds, bounded retries, rate and daily budgets, deterministic idempotency,
  older-observation rejection and append-only redacted audit records.
- Open Food Facts data keeps source, attribution and ODbL metadata.
- AGRIBALYSE data keeps version 3.2, Etalab-2.0 attribution and OFF as its
  current retrieval channel.
- Database, content and image rights are stored separately per source.
- `cached_products` accepts only the `off-odbl` partition; other raw datasets
  require dedicated stores.
- Remote activation fails `G-DATA-LICENSE` until share-alike export,
  correction/deletion and qualified legal review are complete.

## Remote configuration boundary

No URL or key is committed. After the remote activation reviews pass, Flutter
accepts only the public project origin and a publishable or legacy anon key via
build-time definitions:

```bash
flutter run \
  --dart-define=SCANFAIR_SUPABASE_URL=https://PROJECT.supabase.co \
  --dart-define=SCANFAIR_SUPABASE_PUBLISHABLE_KEY=PUBLIC_KEY
```

These values are intentionally absent today. Privileged writer credentials
belong only in managed Edge Function secrets.

## Rollback

Before a remote deployment, create a forward migration that removes or changes
objects explicitly. Never edit a migration that has already been applied to a
shared environment.
