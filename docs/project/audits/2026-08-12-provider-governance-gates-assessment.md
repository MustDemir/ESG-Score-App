# Provider Governance Gates Assessment

- Date: 2026-08-12
- Scope: ScanFair gate-definition quality and Supabase provider governance
- Environment: dedicated `scanfair-dev` project in `eu-central-1`
- Decision: PASS for fail-closed development; remote activation remains blocked

## Verified state

The authenticated Supabase CLI reports `scanfair-dev` as healthy in Frankfurt.
The repository link is stored below the ignored `supabase/.temp/` path. No
remote schema, Edge Function, mobile configuration or personal data has been
activated. A database push dry run resolved exactly seven reviewed migrations.

The official DPA version marker is `Version 1 - August 1, 2026`; the official
subprocessor list marker is `Updated June 1, 2026`. The cost-control source
continues to state that Spend Cap is a Pro feature and that Free Plan usage is
not charged. Online checks retain only decisions and expected markers, not
copies of provider legal content.

## Implemented controls

| Control | Result |
|---|---:|
| Gate-definition normalized seven-attribute validation | PASS |
| Canonical metadata and semantic validation | PASS |
| Gate-definition self-tests | 11/11 PASS |
| Provider-governance self-tests | 26 assertions PASS |
| DPA development profile | PASS, owner approval pending |
| Subprocessor development profile | PASS, owner approval pending |
| Free Plan cost-control development profile | PASS |
| Online provider version-marker check | 3/3 PASS |
| Full development quality pipeline | 29/29 PASS |
| Remote provider profile | EXPECTED FAIL, 0/3 gates with 9 blocking findings |

`G-GATE-DEFINITION-QUALITY` validates all gate files through canonical or
explicit legacy compatibility fields. New definitions use only
`scanfair-gate-v1`. `G-PROVIDER-DPA`, `G-PROVIDER-SUBPROCESSORS` and
`G-COST-CONTROL` produce separate evidence and GitHub Actions results. Strict
profiles additionally require one typed provider-approval artifact bound to
the reviewed commit, provider register, official source versions and a review
artifact through SHA-256 digests.

## Remaining blockers

- DPA and subprocessor decisions still require owner approval.
- Subprocessor change notifications are not yet confirmed as subscribed.
- Free Plan dashboard evidence is user-confirmed but not retained as reviewed evidence.
- The feature branch is not pushed, reviewed or merged into protected `main`.
- Remote migrations, Edge secrets and writer deployment have not occurred.
- Independent writer-security and operational-readiness reviews are pending.
- Privacy and data-license remote profiles remain blocked.

The strict `remote_backend` run blocked all three provider gates. Each gate
correctly detected the missing remote deployment; DPA additionally required
owner approval, subprocessors required approval plus confirmed notifications,
and cost control required reviewed dashboard plan evidence. All three also
required the missing typed, hash-bound provider approval evidence.

This assessment is process and development evidence. It is not legal advice,
production approval, a penetration test or an App Store release decision.
