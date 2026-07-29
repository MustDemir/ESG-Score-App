# Code Quality, Accessibility and CI Audit

## Audit Record

| Field | Value |
|---|---|
| Audit date | 2026-07-28 |
| Normalized | 2026-07-29 |
| Project | ScanFair / ESG-Score-App |
| App baseline | `main` at `60402f8` |
| Supply-chain baseline | `compliance/supply-chain-baseline` at `9b90f33` |
| Remediation merge | PR [#9](https://github.com/MustDemir/ESG-Score-App/pull/9), merge commit `83c0fa0` |
| Owner | Mustafa Demir |
| Reviewer role | AI-assisted engineering audit, human-owned decisions |

## Scope

Reviewed:

- `ESGScoreCalculator`, its existing unit tests and ADR 0010/0011
- result-screen score widgets, typography tokens and custom semantics
- GitHub Actions supply-chain workflow and repository prerequisites
- supply-chain exception and Action-pin validation
- project-documentation traceability for resulting findings

The local Supabase/RLS baseline and its automated tests were inspected in the
same session. No separate unresolved RLS defect was identified.

## Exclusions

This was a static and automated engineering review, not:

- a completed VoiceOver, Dynamic Type or Reduce Motion device test
- a legal accessibility-conformance opinion
- an App Store acceptance guarantee
- an external penetration test
- a scientific validation of the ESG methodology

These exclusions remain visible in R-AS-29, the Apple release gates and the
OWASP MASVS work package.

## Method

1. Compared implemented score behavior with ADR 0010 and ADR 0011.
2. Inventoried existing calculator and traffic-light test cases.
3. Calculated WCAG contrast ratios from the actual Flutter color tokens.
4. Inspected Material-provided and custom widget semantics separately.
5. Executed the supply-chain controls locally and through pull-request CI.
6. Verified repository visibility, owner type, branch rules and Actions
   settings through the GitHub API.
7. Retained only findings with a concrete remediation or verification path.

## Findings

### AUD-2026-07-28-01: Result Accessibility

**Disposition:** confirmed with corrected measurements  
**Priority:** P1  
**Backlog:** TODO-027  
**Requirement/Gate:** R-AS-29, G-AS-REVIEW-READINESS

Evidence:

- `ink3` (`#7A857F`) on white is approximately `3.83:1`, below the `4.5:1`
  threshold for normal text.
- `trafficYellow` (`#D97706`) on white is approximately `3.19:1`. The 72 px
  score number meets the large-text contrast threshold, so the original claim
  that it failed large-text contrast was inaccurate.
- The same yellow text on its 12 percent alpha pill background is approximately
  `2.81:1` and does not meet normal-text contrast.
- `ink3` is used by both `bodySmall` and `meta`, so the affected surface is
  broader than the original finding stated.
- The absence of explicit `Semantics` widgets is not by itself a failure because
  Material widgets provide semantics. Custom ScoreHero and PillarBars still
  need explicit VoiceOver values, and the decorative product emoji should not
  produce misleading speech output.

Required closure evidence:

- automated contrast assertions for relevant foreground/background pairs
- widget semantics tests for ScoreHero and PillarBars
- physical-device VoiceOver and Dynamic Type review record

### AUD-2026-07-28-02: Scoring Decision Tests

**Disposition:** confirmed, original scope overstated  
**Priority:** P1  
**Backlog:** TODO-028  
**ADR:** 0010, 0011

The original statement that only a green happy path and palm-oil case existed
was inaccurate. Tests already covered:

- full green GEPA score
- missing Eco-Score as `dataIncomplete`
- organic and Fair Trade social boosts
- palm-oil penalty
- OFF-to-product mapping

Material gaps remain:

- only-E and completely empty pillar states
- two-pillar weighted average
- regional/EU, vegan and Rainforest Alliance/UTZ branches
- isolated Governance bonuses and warning penalty
- lower and upper score clamping
- green/yellow/red/grey boundary behavior

The lower Environmental clamp is reachable through public behavior because the
Open Food Facts mapper accepts a negative numeric score and the calculator
clamps it to zero. The test matrix must therefore include a negative mapped
Environmental score without exposing a private helper.

### AUD-2026-07-28-03: Dependency Review Prerequisites

**Disposition:** resolved through remote verification  
**Priority:** P2  
**Backlog:** TODO-029  
**ADR:** 0026

GitHub API and PR evidence established:

- the repository is public
- the owner is a personal user account
- Dependency Review is available without GitHub Advanced Security
- Gitleaks Action does not require an organization license for this owner
- PR #9 executed Dependency Review inside the successful supply-chain job

The original conditional-skip proposal is therefore not required. OPA and
Conftest checksum failures after a version-only bump are intended fail-closed
behavior, not a defect.

Verification:

- PR run [30440398821](https://github.com/MustDemir/ESG-Score-App/actions/runs/30440398821): five of five jobs passed
- post-merge run [30440723805](https://github.com/MustDemir/ESG-Score-App/actions/runs/30440723805): five of five jobs passed
- repository-wide Action SHA pinning enabled
- G-SUPPLY-CHAIN added as the fifth required `main` check

### AUD-2026-07-28-04: Scoring Decision Precedence

**Disposition:** confirmed  
**Priority:** P1  
**Backlog:** TODO-030  
**ADR:** 0010, 0011

ADR 0011 states that an S-only score may become the total score. ADR 0010 and
the implementation require an Environmental score before displaying a total.
The implementation is conservative and remains unchanged.

ADR 0011 must not be edited in place because accepted ADRs are append-only.
Closure requires a new decision that defines precedence and the updated
minimum test contract.

### AUD-2026-07-28-05: Duplicate Display Formatting

**Disposition:** confirmed, low impact  
**Priority:** P3  
**Backlog:** TODO-031

The `0..100` to `0..10` display conversion occurs in three score widgets. It
should be centralized in a presentation formatter or Dart extension rather
than coupling display formatting to the scoring domain model.

### AUD-2026-07-29-06: Artifact Action Runtime Deprecation

**Disposition:** newly observed during post-merge verification  
**Priority:** P2  
**Backlog:** TODO-032

Post-merge run `30440723805` reports that the pinned
`actions/upload-artifact@v4.6.2` targets deprecated Node.js 20 and is currently
forced onto Node.js 24 by GitHub. The workflow still passes, but the Action
must be upgraded through a separately reviewed dependency PR and repinned to
the verified release commit.

### AUD-2026-07-29-07: Transitive Action Pinning

**Disposition:** remediated in PR #14
**Priority:** P0
**Improvement:** IMP-COMP-001

After repository-wide Action SHA pinning was enabled, PR run
`30441848323` rejected three jobs before execution. The workflow pinned
`subosito/flutter-action` to a full commit SHA, but that composite Action
referenced `actions/cache@v5` through a mutable tag. GitHub correctly applied
the repository rule to the transitive reference.

The remediation keeps strict SHA enforcement enabled:

- the composite Flutter setup Action was removed
- official Flutter 3.44.0 archives are selected by runner OS and architecture
- Linux x64, macOS x64 and macOS arm64 archives have fixed SHA-256 values
- only the downloaded archive is cached, and its checksum is verified in every
  job before extraction
- `actions/cache@v6.1.0` is referenced directly by full commit SHA
- the cache-hit installer path has an automated regression test

Closure requires all five PR checks to pass while repository-wide SHA pinning
remains enabled.

## Overall Decision

The supply-chain baseline is accepted and merged. Accessibility and scoring
contract findings remain open and must be closed before the release-candidate
profile. Strict transitive Action pinning remains enabled and PR #14 must
provide the remote closure evidence for AUD-2026-07-29-07. The audit does not
block continued local development, but customer score claims must not expand
before TODO-028 and TODO-030 are resolved.
