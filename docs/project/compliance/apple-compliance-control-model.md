# Apple compliance control model

Last updated: 2026-07-27

## Objective and boundary

ScanFair shall reach App Store submission with reproducible evidence for the
applicable Apple rules, platform requirements, privacy obligations, third-party
rights and internal release criteria. A green pipeline is strong release
evidence, but cannot guarantee acceptance: Apple retains reviewer discretion,
rules change, and legal sufficiency can require qualified human review.

The operational source of truth is the chain:

`source-register -> requirement -> gate -> policy/manual check -> evidence`

The February 2026 German PDF remains a historical baseline. The reviewed Apple
App Review Guidelines baseline is the official web version dated 2026-06-08.

## Strict without blocking normal development

| Classification | Development | Release candidate | Submission |
|---|---|---|---|
| Applicable objective MUST | BLOCK | BLOCK | BLOCK |
| Missing release-only MUST evidence | WARN | BLOCK | BLOCK |
| CONDITIONAL_MUST, feature inactive | NOT APPLICABLE | NOT APPLICABLE | NOT APPLICABLE |
| CONDITIONAL_MUST, feature active | BLOCK | BLOCK | BLOCK |
| External SHOULD | WARN | WARN or documented decision | WARN or documented decision |
| Internal MUST adopted by ADR | BLOCK | BLOCK | BLOCK |

Feature flags do not waive rules. They declare applicability and must match the
shipped binary. Enabling accounts, tracking, location, purchases, social login,
third-party AI, chatbots or user-generated content activates additional controls.

## Automation ceiling

- `AUTO`: deterministic facts such as file presence, length, syntax or a feature
  flag contradiction.
- `HYBRID`: automation verifies artifact completeness; a person decides semantic,
  legal, visual or on-device behavior and records evidence.
- `MANUAL`: used only when no meaningful deterministic pre-check exists.

Rego must not invent Apple thresholds. Internal quality heuristics are labelled
`internal` or `SHOULD` and cannot be represented as Apple rejection rules.

## Eight Apple decision gates

| Gate | Scope | Automation |
|---|---|---|
| `G-AS-BUILD-INTEGRITY` | iOS build, SDK, privacy manifest, APIs | HYBRID |
| `G-AS-PRIVACY` | privacy policy, App Privacy, consent, conditional privacy controls | HYBRID |
| `G-AS-CAMERA` | purpose text, runtime consent/indicator, fallback | HYBRID |
| `G-AS-METADATA` | names, screenshots, age rating, brand review | HYBRID |
| `G-AS-REVIEW-READINESS` | completeness, reviewer access, device and IPv6 tests | HYBRID |
| `G-AS-CLAIMS-TRANSPARENCY` | ESG method, sources, limitations and substantiation | HYBRID |
| `G-AS-THIRD-PARTY-RIGHTS` | SDK, data, asset and OFF license rights | HYBRID |
| `G-AS-SUPPORT-IDENTITY` | support, contact and legal provider identity | HYBRID |

The eight gates are decision points, not the number of underlying rules. The
catalog currently contains 19 requirement specifications and can grow without
creating one gate for every guideline paragraph.

`G-AS-BUILD-INTEGRITY` currently combines three independent evidence layers:

1. source validation of the app-owned `PrivacyInfo.xcprivacy`;
2. a versioned SDK and required-reason review bound to dependency and plugin
   hashes;
3. a macOS/Xcode audit of every privacy manifest in the built `Runner.app`.

The current Flutter bundle declares file-timestamp and system-boot-time
required-reason APIs with reason codes in the Flutter privacy manifest.
`mobile_scanner` ships a privacy manifest without tracking, collected-data or
required-reason declarations. Any reviewed input change invalidates the
versioned review and blocks `release_candidate`. The simulator build also
verifies that every bundled framework signature is internally valid. It cannot
prove publisher-signature continuity for Apple's listed binary SDKs, so that
evidence remains a release blocker until validation of the signed archive.

## Source governance

`source-register.yaml` records authority, version, normative weight, scope and
next review date. An overdue source review warns in development and blocks
`release_candidate` and `submission`. The register covers Apple acceptance and
platform material, GDPR, German DDG, OFF licenses and the internal scoring model.

Apple approval is not treated as legal approval. Privacy, provider information,
licenses and environmental claims retain explicit human review steps.

## Commands

```bash
# Daily development controls. Release-only gaps remain visible as warnings.
bash scripts/quality/run_quality_gates.sh

# Strict release rehearsal. Any unresolved applicable MUST blocks.
COMPLIANCE_PROFILE=release_candidate bash scripts/quality/run_quality_gates.sh

# Final submission profile additionally requires signed manual evidence.
COMPLIANCE_PROFILE=submission bash scripts/quality/run_quality_gates.sh
```

GitHub Actions exposes the same three profiles through `workflow_dispatch` and
publishes the aggregate report, all eight gate decisions and the evidence chain.
