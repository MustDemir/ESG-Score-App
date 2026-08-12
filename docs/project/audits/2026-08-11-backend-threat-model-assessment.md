# Backend Threat Model Assessment

## Assessment Record

- Date: 2026-08-11
- Branch: `compliance/backend-threat-model`
- Scope: planned EU Supabase public-read and trusted-writer data path
- Excluded: cloud provisioning, deployment, production data, authentication,
  TestFlight, App Store release and penetration-test execution
- Method: STRIDE with OWASP API Security Top 10 2023, OWASP MASVS 2.1 and
  GDPR Article 32 control overlays

## Result

The architecture is definition-of-ready for controlled implementation, not
approved for remote activation. Twelve threats and eight abuse cases cover
client spoofing, unauthorized writes, secret disclosure, upstream poisoning,
SSRF, missing auditability, resource exhaustion, replay, overbroad reads,
license contamination, stale-data behavior and privileged operator/CI access.

ADR 0032 fixes the central boundary: Flutter is an untrusted read-only client
and may carry only a publishable key. A separate trusted server workload owns
upstream retrieval, validation, idempotent publication and privileged writes.
The mobile app cannot invoke that writer.

## Enforced Controls

- separate local, development, staging and production projects
- exact Frankfurt region `eu-central-1` for remote development
- no personal data in remote development
- forced RLS and explicit least-privilege grants
- fixed HTTPS upstream host, no runtime URL input, redirect revalidation and
  private/link-local target denial
- bounded request, batch, response, retry, concurrency and daily budgets
- transactional idempotency and out-of-order rejection
- append-only redacted audit records
- rotation and time-limited break-glass contract
- typed, repository-internal and SHA-256-bound activation evidence

## Gate Evidence

`G-BACKEND-BOUNDARY` validates the machine-readable contracts and scans Flutter
for prohibited privileged credential markers. Its self-test proves positive
development behavior and negative remote, missing-control, key-leak and
tampered-evidence paths. The full local quality pipeline supplies the final
integration result for this branch.

## Residual Findings

- `GAP-005` remains `in_progress`: actual AuthN/AuthZ, parser, SSRF, rate,
  replay, audit and incident tests require the `NEXT-05` implementation.
- `RISK-008` remains open until the writer exists and receives an independent
  security review or risk-based penetration test.
- Remote activation remains blocked by environment, DPA/region,
  writer-security and operational-readiness evidence.
- Data-license, privacy, claim and App Store release gates remain independent
  blockers and cannot be waived by this assessment.
