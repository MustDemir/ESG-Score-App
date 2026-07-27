# ESG data architecture

## Objective

ScanFair separates external facts, normalized evidence and the versioned score.
A database never returns an unexplained ESG judgment.

```text
External source
  -> source-specific adapter
  -> ScanFairProduct + ESGEvidence
  -> evidence-backed entity and relationship resolution
  -> versioned parameter/profile resolution
  -> ESGScoreCalculator
  -> result and provenance UI
  -> optional Supabase cache / score snapshot
```

Each `ESGEvidence` item records:

- source and license
- source record and original field
- metric, value and optional unit
- affected ESG pillar and subject scope
- quality class
- retrieval time, source observation time and schema version
- optional retrieval channel when an upstream dataset is transported by
  another API

Each `ESGRelationship` records:

- the source and target entity
- relationship type and assertion class
- source record and supporting evidence IDs
- confidence, retrieval time and optional validity period
- whether the relationship is approved as a score input

## Current integration

Open Food Facts is the live product and delivery API. The adapter accepts
current `environmental_score_*` fields and legacy `ecoscore_*` fields. The API
is treated as a changing community dataset: missing data is not estimated and
source-calculated values are distinguished from community-provided fields.

AGRIBALYSE 3.2 is the first active upstream environmental reference. When OFF
provides an AGRIBALYSE code, version 3.2 and climate-change value, the adapter
records AGRIBALYSE as the evidence source and OFF as the retrieval channel.
The DQR is retained. The value remains a category average, not a measured
footprint of the scanned brand product, and is not active in formula v1.0.

The OFF adapter also resolves available commodity, product-origin and brand
signals into explicit relationships. OFF community data is retained as
`community_reported` or `inferred`, with low confidence and
`score_eligible: false`. A generic product origin is not assigned to every
ingredient. Therefore current OFF relationships cannot yet trigger
commodity-country risk or legal-entity governance factors.

## Identity and relationship boundary

The join path is explicit:

```text
GTIN product
  -> contains_commodity
  -> commodity_has_origin
  -> contextual environmental/social risk

GTIN product
  -> marketed_by_brand
  -> responsible_legal_entity
  -> company governance evidence
```

Commodity-country risk requires both score-eligible links. Governance requires
a score-eligible legal-entity resolution. Missing links block the affected
factor and reduce confidence; they never create a neutral or positive value.

The app currently calls Open Food Facts directly. Supabase is prepared as an
optional cache and evidence store, but no remote project or Flutter SDK is
connected yet.

## Supabase boundary

The local migrations define:

| Table | Purpose | Client access |
|---|---|---|
| `data_sources` | source, license and API metadata | read active rows |
| `cached_products` | allowlisted source payload cache | read fresh rows |
| `product_evidence` | normalized, published evidence | read published rows |
| `score_snapshots` | reproducible formula output | read published rows |
| `scans` | account-linked scan history | owner only |
| `methodology_versions` | formula lifecycle and publication state | read published rows |
| `parameters` | versioned ESG and confidence definitions | read published rows |
| `category_profiles` | inheriting food-category profiles | read published rows |
| `profile_parameters` | applicability and priority per profile | read published rows |
| `source_mappings` | reviewed evidence-to-parameter mappings | read published rows |
| `traceability_entities` | products, commodities, origins, brands and legal entities | read published rows |
| `traceability_entity_identifiers` | GTIN, ISO country, LEI and mapping identifiers | read identifiers of published entities |
| `traceability_relationships` | evidence-backed subject links and score eligibility | read published rows |

All thirteen tables use RLS. Product data, evidence, relationships, scores and methodology can only
be written by a trusted backend path. Draft methodology is invisible to
clients. A Supabase service-role key must never be embedded in the Flutter app.

`G-DATA-ARCH` validates migration structure, grants and licensing without
Docker. `G-DATA-RLS` rebuilds PostgreSQL and runs pgTAP behavior tests locally
and in GitHub Actions. `G-METHOD-CATALOG` validates the YAML source of truth,
profile inheritance, allowed claims and the separation of ESG from confidence.
`G-LINK-INTEGRITY`, `G-MISSING-DATA`, `G-RED-FLAG`, `G-SCORE-REPRO` and
`G-CLAIM-SAFETY` validate the draft scoring safety controls independently.

## Methodology boundary

Formula v1.0 remains active for the local MVP. The hierarchical
`2.0-draft` catalog contains 26 reusable parameters, a food base profile and
pilot profiles for coffee, bananas and cocoa/chocolate. Its numerical weights
remain deferred. One raw `E-GHG-INTENSITY` category mapping from AGRIBALYSE is
validated but not score-active until product mapping and calibration are
complete.

Country or commodity risk is contextual evidence, not proof of a violation by
a scanned product. Missing relevant evidence reduces data confidence; a
confirmed non-applicable parameter does not.

`scoring-controls.yaml` defines the activation barriers for methodology 2.0.
Only measured, verified or attributable declared relationships with at least
medium confidence can become score inputs. Category averages, community data
and inferred links remain visible evidence but are score-ineligible by default.
Severe confirmed social findings are non-compensatory; the exact numerical
handling remains deferred until calibration and expert review.

## License boundary

Open Food Facts database data is ODbL-licensed and requires attribution and
share-alike handling. AGRIBALYSE 3.2 uses Etalab Open Licence 2.0 and requires
ADEME attribution. Sources remain logically separated and the retrieval
channel is explicit, avoiding a combined anonymous dataset.

## Next increments

1. Build verified commodity-origin bindings for pilot products.
2. Validate WRI Aqueduct only after the origin join passes link integrity.
3. Resolve brand to legal entity through GLEIF/BRIS-compatible identifiers.
4. Calibrate GHG normalization and missing-data behavior with test products.
5. Create a dedicated EU development project and retain DPA/region evidence.
6. Add a server-side cache writer and a read-only Flutter cache adapter.

## Primary references

- Open Food Facts API documentation:
  https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/
- Open Food Facts API/schema change log:
  https://openfoodfacts.github.io/openfoodfacts-server/api/ref-api-and-product-schema-change-log/
- Open Food Facts license guidance:
  https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/
- AGRIBALYSE 3.2 dataset:
  https://doi.org/10.57745/XTENSJ
- AGRIBALYSE license and usage conditions:
  https://doc.agribalyse.fr/documentation/utiliser-agribalyse/precautions-et-conditions-dusage
- Supabase local migrations:
  https://supabase.com/docs/guides/local-development/database-migrations
- Supabase Row Level Security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
- GS1 Global Traceability Standard and EPCIS:
  https://www.gs1.org/standards/traceability
- GLEIF API for legal-entity and ownership data:
  https://www.gleif.org/en/lei-data/gleif-api
- U.S. Department of Labor ILAB goods list:
  https://www.dol.gov/agencies/ilab/reports/child-labor/list-of-goods
