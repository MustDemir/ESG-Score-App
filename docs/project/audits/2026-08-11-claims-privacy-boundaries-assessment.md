# Claims and Privacy Boundary Assessment

- Audit date: 2026-08-11
- Normalized: 2026-08-11
- Branch reviewed: `compliance/claims-privacy-boundaries`
- Owner: Mustafa Demir
- Disposition: development controls pass; external activation remains blocked

## Scope

Reviewed were the current iOS runtime claim presentation, explicit and implied
ESG/nutrition claims, camera and Open Food Facts data flow, runtime retention,
Apple privacy declarations and the planned remote boundary. The assessment
does not constitute legal, nutritional, ESG/LCA or App Store approval.

## Primary Sources

- Apple App Review Guidelines and App Privacy Details
- GDPR Articles 5, 6, 13, 25, 28, 30, 32 and 35
- EDPB DPIA Guidelines WP248 rev.01 and BfDI DPIA guidance
- Directive (EU) 2024/825 and its German UWG implementation path
- Regulation (EC) 1924/2006 and the EU Register of Nutrition and Health Claims

The versioned source references and review dates are maintained in
`docs/project/compliance/source-register.yaml`.

## Findings and Disposition

| ID | Severity | Finding | Disposition |
|---|---:|---|---|
| CP-01 | High | The former `Gesundheit` card used beneficial wording and a progress bar, creating an implied health ranking. | Remediated: neutral `Nährwert-Hinweis`, factual source fields, no score/bar, explicit no-advice disclosure. |
| CP-02 | High | The former privacy text denied personal-data transmission although OFF/network infrastructure can process IP and request metadata. | Remediated in the current development draft and data inventory. |
| CP-03 | High | App, App Store and website claims lacked one activation inventory and qualified release evidence. | Partially remediated: inventory and fail-closed gate exist; calibration and legal/domain reviews remain blockers. |
| CP-04 | High | Provider role, region, retention and legal basis for direct OFF lookup are not qualified. | Open and release-blocking in `G-PRIVACY-BOUNDARY`. |
| CP-05 | High | External beta lacks final controller address, approved privacy text, App Privacy Details and DPIA screening. | Open and release-blocking. |
| CP-06 | High | Planned backend lacks processor, rights, deletion and incident evidence. | Open; remote profile blocks activation and NEXT-04 must add the threat model. |

## Implemented Controls

- `claim-inventory.yaml` covers app runtime, App Store and website marketing,
  including claim class, method version, evidence, confidence and release state.
- `privacy-data-inventory.yaml` covers seven current or planned processing
  activities with purpose, necessity, recipient, region and retention.
- `privacy-data-flow.md` separates the active direct-OFF path from the disabled
  backend and records the DPIA decision path.
- ADR 0031 defines development, external-beta, remote and release boundaries.
- `G-CLAIM-GOVERNANCE` and `G-PRIVACY-BOUNDARY` reject placeholder approvals;
  strict evidence must satisfy typed fields, repository path constraints and
  SHA-256 binding to both inventory and reviewed artifact.

## Validation

- Claims development profile: PASS
- Privacy development profile: PASS
- Claims gate self-tests: PASS, 7 assertions
- Privacy gate self-tests: PASS, 8 assertions
- Release-candidate claims profile: EXPECTED FAIL on pending activation,
  calibration, legal and subject-matter evidence
- Release-candidate privacy profile: EXPECTED FAIL on controller, legal basis,
  disclosure, App Privacy Details and DPIA evidence
- Flutter analyze: PASS without findings
- Flutter test: PASS, 93/93 tests
- Flutter line coverage: 1287/1516 = 84.89 percent
- Full development quality pipeline: PASS, 24/24 gates
- Native unsigned iOS simulator build and bundled privacy-manifest audit: PASS
- Project-Control: PASS, 16 improvements and 14 lifecycle gaps
- YAML syntax: PASS, 111 project YAML files

## Exit Decision

Local development may continue. External beta, public marketing, remote
backend and release candidate are not approved. NEXT-04 may begin only after
this branch is integrated; it must keep the backend disabled while threat,
processor, retention, rights and incident controls are designed.
