# Backend Activation Evidence

This directory is intentionally empty until a real remote implementation is
reviewed. Future evidence must:

- use one of the evidence types defined in
  `../eu-supabase-environment-contract.yaml`
- reference repository-internal review artifacts only
- bind the environment contract, threat model and artifact with lowercase
  SHA-256 digests
- contain no credentials, authorization headers or raw personal payloads
- be generated from actual environment, writer-security or operational tests

Placeholder approvals are invalid. `G-BACKEND-BOUNDARY` verifies every record
before the `remote_backend` profile can pass.
