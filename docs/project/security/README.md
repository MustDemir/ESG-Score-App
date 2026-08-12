# Backend Security Source of Truth

This directory contains the security source of truth for the locally
implemented remote data path. It does not represent a deployed or enabled
backend.

- `backend-threat-model.yaml` is the machine-readable STRIDE/OWASP API threat
  and abuse-case model.
- `backend-threat-model.md` renders the trust boundaries and fixed security
  invariants for review.
- `eu-supabase-environment-contract.yaml` defines environment isolation,
  identities, keys, writer inputs, resource limits, idempotency, audit,
  incident handling and activation evidence.
- `evidence/` is reserved for future typed review records and their referenced
  artifacts. Evidence must match the contract schema and SHA-256 digests.

Local validation:

```bash
ruby scripts/quality/test_backend_boundary_gate.rb
node --test supabase/functions/_shared/writer_contract.test.mjs
ruby scripts/quality/validate_backend_boundary.rb --profile development
```

The development profile covers the local writer, database and Flutter read
adapter while keeping remote activation disabled. The `remote_backend` profile
is expected to fail until a dedicated Frankfurt development environment is
provisioned and all three activation-review contracts are closed.
`release_candidate` always
requires a fourth, release-specific security review bound to the reviewed
commit. No credentials belong in this directory.
