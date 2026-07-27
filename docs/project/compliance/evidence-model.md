# Compliance evidence model

Last updated: 2026-07-19

## Evidence categories

| Category | Examples | Trust rule |
|---|---|---|
| A: extracted | Info.plist display name, camera purpose, privacy-manifest validity, hash-bound SDK review, required docs | Shipped files override declarations |
| B: declared | feature activation, public URLs, App Store metadata state | Must be reviewed whenever the related feature changes |
| C: hybrid | on-device behavior, screenshots, legal/license review, claims substantiation | Reviewer, date, scope and evidence URI are required for submission |

`extract_app_metadata.sh` creates `app_extracted.json` from repository files.
`build_compliance_input.sh` merges this with `compliance-manifest.json`; extracted
facts win. `run_gates.sh` evaluates only production policies and appends one
versioned record to `evidence-log.jsonl`.

The iOS privacy review is retained in `ios-privacy-sdk-review.json`. Its
approval is current only while the SHA-256 values of `pubspec.lock`, the app
privacy manifest and `GeneratedPluginRegistrant.m` match the reviewed values.
The macOS build gate independently inspects the shipped `Runner.app` and writes
`ios_privacy_audit.json`. The technical review deliberately does not mark App
Store Connect privacy answers or legal data classification as complete.

Each version-2 evidence record contains:

- profile and aggregate decision
- per-gate PASS, WARN or FAIL with messages
- input SHA-256
- commit SHA, branch/ref, workflow run ID and actor
- dirty-working-tree marker for local runs
- previous-entry hash and current-entry hash

`verify_evidence_chain.sh` recomputes every entry hash and every previous-hash
link. The log is tamper-evident, not an immutable external archive. GitHub Actions
artifacts preserve each CI run; a production evidence store remains future work.

## Profiles

`development` keeps unfinished release evidence as visible warnings.
`release_candidate` converts all applicable release evidence gaps into failures.
`submission` additionally requires a final manual attestation with evidence URI.

The manifest must remain truthful. A feature flag set to false while the feature
exists in the binary is a compliance defect, not a permitted workaround.

## Local commands

```bash
ruby scripts/compliance/validate_compliance_catalog.rb
opa test docs/project/policies
COMPLIANCE_PROFILE=development bash scripts/compliance/run_gates.sh
bash scripts/compliance/verify_evidence_chain.sh
```

Expected current behavior: development passes with explicit release warnings;
release_candidate fails until privacy, metadata, device, claims, license and
support evidence are complete.
