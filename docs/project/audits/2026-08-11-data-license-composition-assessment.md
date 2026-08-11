# ScanFair Data-License Composition Assessment

Audit date: 2026-08-11
Branch: `compliance/data-license-composition`
Scope: NEXT-02 / GAP-003 / IMP-COMP-005
Status: local development controls validated; remote activation blocked
Owner: Mustafa Demir

## 1. Decision boundary

This assessment defines a conservative engineering architecture for Open Food
Facts, AGRIBALYSE and restricted product declarations. It is not legal advice
and does not close the required qualified data-licensing review.

The reviewed primary sources distinguish Open Food Facts database rights,
individual contents and product images. ODbL separately defines Produced Work,
Derivative Database and Collective Database and imposes attribution,
share-alike and access duties depending on public use. Current Open Food Facts
cache guidance additionally instructs implementers not to mix OFF data with
external product data.

Primary sources:

- https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/
- https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/creating-a-local-cache-of-open-food-facts-data/
- https://opendatacommons.org/licenses/odbl/1-0/
- https://opendatacommons.org/licenses/dbcl/1-0/
- https://creativecommons.org/licenses/by-sa/3.0/
- https://www.etalab.gouv.fr/wp-content/uploads/2018/11/open-licence.pdf

## 2. Conservative classification

| ScanFair scenario | Classification | Current decision |
| --- | --- | --- |
| Direct OFF API result in the app | Produced Work | Allowed locally with associated attribution and provenance |
| OFF raw or normalized remote cache | Derivative Database | Blocked until isolated store, share-alike export and legal review exist |
| Source-partitioned evidence index | Collective Database candidate | Schema-only; remote activation requires legal confirmation |
| Score snapshot and result UI | Produced Work candidate | Allowed locally; public classification remains subject to legal review |
| Persisted OFF product images | Separate CC BY-SA 3.0 content | Remote persistence prohibited pending image-rights review |

The classifications intentionally choose the stricter plausible path. They do
not claim that a court or qualified counsel has confirmed the classification.

## 3. Architecture decision

ADR 0030 supersedes ADR 0003 because the earlier record incorrectly described
the database itself as CC BY-SA. The current contract separates:

- OFF database: ODbL 1.0
- OFF individual contents: DbCL 1.0
- OFF product images: CC BY-SA 3.0
- AGRIBALYSE data: Etalab Open Licence 2.0
- GEPA publication content: restricted; factual declarations and provenance only

`public.cached_products` is now the isolated `off-odbl` partition. The
`enforce_cached_product_license_boundary` trigger rejects every other source.
AGRIBALYSE and future external raw datasets require dedicated stores. The
normalized evidence index may retain source-partitioned factual records and
provenance, but no external raw product payloads.

The app's detail view exposes database, content and image licenses separately,
keeps contributor attribution with the product result and displays the ODbL
and image-license URIs.

## 4. Enforcement profiles

`G-DATA-LICENSE` has three profiles:

| Profile | Expected behavior |
| --- | --- |
| `development` | Passes only while the remote backend is disabled and design controls are tested |
| `remote_backend` | Requires enabled backend plus repository-backed activation, legal-review, export and correction/deletion evidence |
| `release_candidate` | Inherits remote requirements and additionally requires verified in-app and image attribution evidence |

The current remote profile fails closed for eight reasons:

1. Remote backend is disabled.
2. Repository-backed remote-activation evidence is absent.
3. Qualified legal review is pending.
4. Repository-backed legal-review evidence is absent.
5. Machine-readable share-alike export is design-only.
6. Correction and deletion are design-only.
7. Repository-backed share-alike export evidence is absent.
8. Repository-backed correction and deletion evidence is absent.

This is an intentional control result, not a failed local deliverable.
`COMPLIANCE_PROFILE=release_candidate` and `submission` automatically select
the strict data-license release profile; they cannot silently fall back to the
development contract. Every activation artifact must also match its typed
evidence contract, including role, scope, timestamp and a SHA-256 digest;
status labels or arbitrary repository files do not satisfy the gate.

## 5. Verification evidence

| Check | Result |
| --- | --- |
| Data-license validator self-tests | 8/8 PASS, 31 assertions; valid typed evidence also proves the remote profile is reachable |
| Development data-license profile | PASS |
| Remote data-license profile | Expected FAIL with eight explicit blockers |
| Full local quality pipeline | 22/22 PASS |
| Flutter tests | 91/91 PASS |
| Flutter line coverage | 1291/1520 = 84.93% |
| Attribution widget tests | 2/2 PASS, including 320 px and 200% text scale |
| Supabase migration replay | PASS across six migrations |
| pgTAP database tests | 71/71 PASS |
| PostgreSQL lint | PASS, no schema findings |
| Full release-candidate pipeline | Expected FAIL at MASVS, Apple and data-license gates |

The pgTAP suite proves both directions: an OFF payload can enter the isolated
cache and an AGRIBALYSE payload is rejected with SQLSTATE `23514`.

## 6. GAP-003 disposition

GAP-003 moves from maturity 2 to 3 and remains `in_progress`. The architecture,
contract, migration and automated gate are implemented, but closure maturity 4
requires:

- qualified legal review of the three composition classifications
- machine-readable OFF partition or alteration-file export
- source correction, withdrawal and score invalidation implementation
- review of the final remote Supabase topology before provisioning

No remote project, external beta, TestFlight release or App Store publication
is authorized by this assessment.
