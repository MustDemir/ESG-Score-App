# Backend Security Source of Truth

This directory contains the security definition-of-ready for the planned
remote data path. It does not represent a deployed or enabled backend.

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
ruby scripts/quality/validate_backend_boundary.rb --profile development
```

The `remote_backend` profile is expected to fail until `NEXT-05` provisions
the dedicated Frankfurt development environment, implements the writer and
closes its three activation-review contracts. `release_candidate` always
requires a fourth, release-specific security review bound to the reviewed
commit. No credentials belong in this directory.
