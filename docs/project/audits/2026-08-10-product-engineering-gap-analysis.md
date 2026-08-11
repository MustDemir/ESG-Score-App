# ScanFair Product Engineering Gap Analysis

Audit date: 2026-08-10
Branch: `feature/coffee-reference-case`
Method: [ScanFair Lifecycle Gap Analysis](../methodology/gap-analysis-process.md)
Status: initial baseline
Owner: Mustafa Demir

## 1. Objective

This audit evaluates whether the ScanFair Product Engineering Handbook and the
repository cover the capabilities required to evolve the local iOS MVP into a
scientifically defensible, privacy-preserving, secure, operable and
App-Store-ready product.

The audit deliberately searches for missing and weakly operationalized areas.
It does not treat an existing document, a green development pipeline or a
disclaimer as proof that a legal, scientific or operational obligation has
been met.

This is an engineering and governance assessment, not legal advice. Qualified
legal, privacy, ESG, LCA, human-rights and health-claims review remains required
before the corresponding release decisions.

## 2. Reviewed Scope

- product-engineering handbook and delivery operating model
- roadmap, backlog, risks, definition of done and improvement register
- Apple, GDPR, MASVS and supply-chain control artifacts
- ESG methodology catalog, source registers and scoring safety controls
- Flutter app architecture, tests and physical-device evidence
- Supabase migrations, RLS tests and planned remote trust boundary
- Git history, branch model, GitHub Actions and local quality-gate report

Explicitly excluded:

- legal opinion or certification
- independent ESG/LCA or human-rights expert validation
- penetration test of a production backend, because no production backend exists
- App Store Connect, TestFlight and production operations, because they are not active

## 3. Evidence Baseline

| Evidence | Observed state |
| --- | --- |
| Local quality pipeline | 21/21 gate groups PASS |
| Flutter tests | 85/85 PASS, 82.43% line coverage |
| Database tests | 55/55 pgTAP PASS with migration replay and DB lint |
| iOS validation | camera, permissions, result flow and accessibility tested on a physical iPhone |
| Apple control model | 19 requirements, eight gate groups, three enforcement profiles |
| Security baseline | 24 MASVS 2.1 controls classified; supply-chain gate active |
| Data baseline | evidence-first schema, RLS, source provenance and context-bound relationships |
| Current vertical slice | three coffee pilot GTINs with product-scoped commodity origins |

## 4. External Primary-Source Check

### Apple platform and App Store

The [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
were last updated on 8 June 2026 and explicitly remain a living document. They
require accurate metadata, a functional review path, appropriate security,
privacy policy disclosure, data minimization and in-app account deletion when
account creation is supported. The repository tracks the June 2026 version,
but a repeatable source-diff and impact-review process is not yet operational.

Apple's [Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)
are currently voluntary, but Apple states that accessibility support details
will become required over time. A claimed label requires users to complete all
common tasks using the feature. ScanFair has strong VoiceOver, Larger Text,
contrast and Reduced Motion evidence, but not yet a complete release audit for
Voice Control, differentiation without color, Dark Interface and the App Store
declaration.

Apple requires accurate declarations for app and third-party behavior in
[App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
and valid
[privacy manifests](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk).
Technical bundle checks are present; the remote-backend data-flow and
operational privacy evidence are not.

### Environmental and health claims

[Directive (EU) 2024/825](https://eur-lex.europa.eu/eli/dir/2024/825/oj)
strengthens consumer protection against generic or insufficiently substantiated
environmental claims. Member State measures apply from 27 September 2026.
Because ScanFair presents environmental scores and may market sustainable
purchase guidance, this requires a dedicated claim inventory and legal
applicability review before public release.

[Regulation (EC) No 1924/2006](https://eur-lex.europa.eu/eli/reg/2006/1924/oj)
applies to nutrition and health claims in commercial communications and
requires permitted claims and scientific substantiation. The European
Commission maintains the
[EU Register of Health Claims](https://food.ec.europa.eu/food-safety/labelling-and-nutrition/nutrition-and-health-claims/eu-register-health-claims_en).
ScanFair's separate Health indicator therefore needs an explicit legal and
scientific boundary, even though it is not part of the ESG score.

### Data licensing

Open Food Facts states that its database is licensed under ODbL with attribution
and share-alike conditions and warns that combining it with other databases can
require the resulting database to be open under compatible terms. See the
official [Open Food Facts API reuse conditions](https://support.openfoodfacts.org/help/en-gb/12-donnees-api/94-y-a-t-il-des-conditions-pour-utiliser-l-api).
The current per-source license register is a good foundation, but it does not
yet decide the legal and technical architecture of a combined OFF, GEPA,
AGRIBALYSE and future risk-source database.

### Mobile security

The official [OWASP MASVS](https://mas.owasp.org/MASVS/) still covers storage,
cryptography, authentication, network, platform, code, resilience and privacy.
The repository's MASVS 2.1 control coverage is a strong mobile baseline. The
remaining gap is an end-to-end threat model for the future server writer,
admin path and data-source manipulation, not another generic mobile checklist.

## 5. Capability Maturity Matrix

Maturity uses the scale defined in the SLGA method: 0 not considered, 1
identified, 2 designed, 3 implemented, 4 validated, 5 operationalized.

| Domain | Current | Target before release | Main gap |
| --- | ---: | ---: | --- |
| Product and user value | 3 | 4 | representative field validation and comprehension study |
| UX, accessibility and localization | 3 | 4 | complete common-task audit and App Store accessibility declaration |
| Mobile and iOS | 4 | 4 | no new development blocker; signed archive remains release evidence |
| ESG methodology | 2 | 4 | calibration, sensitivity, reference corpus and external expert review |
| Data and licensing | 2 | 4 | ODbL composition decision, correction and withdrawal process |
| Claims and consumer law | 1 | 4 | environmental and health claim inventory plus qualified review |
| Privacy and data protection | 2 | 4 | operational data flow, retention, rights, AVV, incident and DPIA decision |
| Security and supply chain | 3 | 4 | backend/API threat model and abuse testing |
| Testing and quality | 3 | 4 | performance, reliability, provider failure and representative field tests |
| DevOps and delivery | 4 | 4 | source-freshness impact review must become repeatable |
| Operations and resilience | 1 | 4 | observability, restore, incident, support and score correction drill |
| Release and organization | 2 | 4 | business continuity, metadata, signed archive and human release evidence |

## 6. Findings

The authoritative finding details and closure criteria are stored in
[`gap-register.yaml`](../gap-register.yaml).

| Finding | Priority | Type | Summary | Control mapping |
| --- | --- | --- | --- | --- |
| GAP-001 | P0 | partial | scientific score validation and calibration incomplete | IMP-DEV-001, IMP-DEV-003 |
| GAP-002 | P0 | partial | environmental, sustainability and Health claims lack complete legal governance | IMP-COMP-003, IMP-COMP-004 |
| GAP-003 | P0 | partial | ODbL composition and database separation not decided | IMP-COMP-005, IMP-DEV-002 |
| GAP-004 | P0 | documented, not operational | privacy operating model incomplete | IMP-COMP-003, IMP-COMP-006, IMP-DEV-002 |
| GAP-005 | P1 | partial | future backend has no end-to-end threat model | IMP-COMP-007, IMP-DEV-002 |
| GAP-006 | P1 | absent | performance and provider-resilience budgets missing | IMP-DEV-004, IMP-OPS-001 |
| GAP-007 | P1 | partial | representative product and user field test missing | IMP-DEV-003, IMP-DEV-004 |
| GAP-008 | P1 | partial | complete Apple accessibility release declaration missing | IMP-COMP-003 |
| GAP-009 | P1 | documented, not operational | monitoring, restore, incident and correction drill missing | IMP-OPS-001 |
| GAP-010 | P1 | partial | key-person, account and credential continuity missing | IMP-OPS-002 |
| GAP-011 | P1 | partial | regulatory/source freshness is dated but not fully enforced | IMP-PROC-003 |
| GAP-012 | P2 | partial | dynamic external values and data freshness need localization | IMP-DEV-004 |
| GAP-013 | P1 | documented, not operational | score/data appeal, correction and withdrawal process missing | IMP-OPS-001 |
| GAP-014 | P2 | trigger-based | accounts, payments, UGC, analytics, location and AI need activation controls | IMP-PROC-003 |

Totals: four P0, eight P1 and two P2 gaps. Eleven are open, two are in
progress and one is monitored as a future capability trigger.

## 7. Positive and Unusual Strengths

The audit did not find a weak or unstructured MVP. It found a strong
development system whose remaining gaps are concentrated around scientific,
legal and operational release maturity.

Notable strengths:

- Compliance requirements are executable and evidence-producing instead of a
  release-time checklist.
- Missing environmental evidence blocks an overall ESG score rather than
  generating false precision.
- Product-scoped origin is enforced in Dart, PostgreSQL, tests, ADR and a
  quality gate.
- Accessibility is supported by automated checks and real VoiceOver/device
  evidence.
- Development, release-candidate and submission profiles prevent a green MVP
  pipeline from claiming App Store readiness.
- AI-assisted engineering retains explicit human accountability for claims,
  methodology, risk acceptance and release.

## 8. Recommended Closure Sequence

1. Establish the recurring gap/source-freshness control (`IMP-PROC-003`).
2. Close claim, license and privacy boundaries before a remote combined data
   platform (`IMP-COMP-004` to `IMP-COMP-006`).
3. Complete the evidence-first coffee factors without activating unvalidated
   scoring (`IMP-DEV-001`).
4. Calibrate and independently review the methodology (`IMP-DEV-003`).
5. Threat-model the server writer, then build the remote data path
   (`IMP-COMP-007`, `IMP-DEV-002`).
6. Run performance, provider-failure, representative barcode and user field
   tests (`IMP-DEV-004`).
7. Close Apple/accessibility evidence, operations, correction and business
   continuity before TestFlight or submission (`IMP-COMP-003`, `IMP-OPS-001`,
   `IMP-OPS-002`).

These tracks can overlap, but their activation dependencies must remain
explicit. In particular, more source integrations should not outrun the
license architecture, and a public score should not outrun calibration and
claim review.

## 9. Disposition

- The SLGA method and machine-readable gap register are accepted as the
  recurring control model.
- P0 and P1 findings are mapped to the improvement register with owners and
  profile-based triggers.
- The project-control validator must reject malformed gaps, unknown mappings,
  stale full-review dates and closed gaps without evidence.
- The audit is repeated at phase changes and before remote backend, TestFlight,
  release candidate and submission.
