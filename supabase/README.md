# ScanFair local Supabase schema

This directory prepares the local, migration-based database layer. It is not
linked to a remote project and contains no credentials.

## Local validation

Prerequisites: Docker Desktop and the Supabase CLI.

```bash
supabase start
supabase db reset --local
supabase test db --local
supabase db lint --local --level warning
supabase stop
```

`db reset --local` recreates the local database and applies every migration.
Do not run `db reset --linked` against a non-disposable remote project.
The 51-test pgTAP suite verifies table structure, RLS activation, fact,
methodology and traceability write denial, relationship eligibility
constraints, draft-method visibility and owner-only scan behavior.

Without Docker, the static gates remain available:

```bash
ruby scripts/quality/validate_data_architecture.rb
ruby scripts/quality/validate_methodology_catalog.rb
ruby scripts/quality/validate_scoring_safety.rb --gate link-integrity
```

The app still reads Open Food Facts directly. Formula v1.0 is published;
methodology `2.0-draft` is deliberately hidden by RLS. A later increment will
add the Flutter cache adapter after a dedicated EU Supabase development
project, environment-specific publishable key handling, DPA evidence and the
required Apple privacy review are available.

## Security model

- All public tables have RLS enabled and forced.
- ESG source data is client-readable but server-maintained.
- Upstream evidence can retain a separate `retrieved_via_source_id`.
- Traceability entities, identifiers and relationships are server-maintained.
- Low-confidence, inferred and community relationships cannot be score-eligible.
- Score snapshots retain relationship and red-flag lineage separately.
- Only published methodology is client-readable; catalog writes are server-only.
- Authenticated users can only read, create and delete their own scan rows.
- No service-role key is permitted in Flutter code.
- Open Food Facts data keeps source, attribution and ODbL metadata.
- AGRIBALYSE data keeps version 3.2, Etalab-2.0 attribution and OFF as its
  current retrieval channel.

## Rollback

Before a remote deployment, create a forward migration that removes or changes
objects explicitly. Never edit a migration that has already been applied to a
shared environment.
