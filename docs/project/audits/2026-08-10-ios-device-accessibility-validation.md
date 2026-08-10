# iOS device accessibility validation

## Evidence scope

| Field | Value |
|---|---|
| Date | 2026-08-10 |
| Branch | `quality/ios-device-evidence` |
| Device | Physical iPhone 17 (`iPhone18,3`) |
| Device identifier | `00008150-00063C920C45401C` |
| iOS | 26.5.2 (`23F84`) |
| Xcode | 26.6 (`17F113`) |
| App | ScanFair iOS Flutter MVP |
| Operator | Repository owner on connected physical device |
| Evidence type | Collaborative manual test record based on operator observations |

This record captures the checks performed during the connected-device session.
No screenshot or screen recording was retained. It is development evidence and
does not by itself close release-candidate review readiness.

## Observed results

| Check | Result | Observation |
|---|---|---|
| Release app launch | PASS | App installed, launched and remained stable. |
| Live barcode scanner | PASS | Camera view appeared and a barcode scan completed successfully. |
| Camera permission revoked | PASS | App remained stable, explained missing access and exposed manual entry. |
| Manual barcode fallback | PASS | Barcode `4000417025005` opened the expected result without instability. |
| Camera permission restored | PASS | Live camera and barcode scanning became available again. |
| Largest accessibility text | PASS WITH LIMITED SCOPE | Traversed screens remained usable; no clipping was reported. |
| German VoiceOver app context | PASS | App copy used German pronunciation after declaring the German app locale. |
| Low-data warning semantics | PASS | The complete no-score explanation was announced. |
| Mixed-language ESG pillars | PASS | Environmental, Social and Governance switched to English pronunciation while values remained German. |
| Central terminology regression | PASS | The catalog-based build announced ScanFair and Open Food Facts in English, ESG and RSPO using German letters, surrounding copy in German and `unbekannt` instead of `unknown`. |
| Scanner VoiceOver focus order | PASS | Swipe navigation announced close, light control and scanner instructions in a usable order. |
| Reduce Motion | PASS | Scanner, manual barcode lookup, result and detail navigation remained stable and understandable with Reduce Motion enabled. |

## Changes driven by the test

- Declared German Flutter and iOS bundle localization.
- Applied a German locale to the app semantics subtree.
- Added a complete semantic label to the low-data warning.
- Added explicit English locale attributes to the three ESG pillar names.
- Introduced a central semantic terminology policy and executable catalog.
- Replaced the visible `unknown` fallback wording with `unbekannt`.

## Signing observation

The Flutter CLI release-device output failed strict signature verification for
an embedded framework during this session. A direct Xcode Release build using
automatic signing produced an app bundle that passed strict `codesign`
verification, installed and launched successfully. This difference remains a
toolchain finding to reproduce and resolve before a signed archive is accepted
as release-candidate evidence.

## Remaining device checks

- Capture durable screenshot or screen-recording evidence for the eventual
  release candidate.
- Validate the final signed archive rather than a development-session build.

## Decision

Development accessibility evidence for the current MVP build: **pass**.

`TODO-027` is complete for the current development scope.
`G-AS-REVIEW-READINESS` remains open for the release-candidate profile because
final archive and durable release evidence must be captured again for the
actual release candidate.
