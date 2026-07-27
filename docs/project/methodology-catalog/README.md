# ScanFair methodology catalog

This directory is the source of truth for the draft ScanFair scoring
methodology after MVP formula v1.0.

## Layers

1. `parameters.yaml` defines reusable ESG and data-confidence parameters.
2. `profiles/food-base.yaml` defines the common packaged-food core.
3. Category profiles inherit the food core and override applicability and
   priority for coffee, bananas and cocoa/chocolate.
4. `source-mappings/` binds reviewed raw source fields to parameters.
5. `scoring-controls.yaml` defines link, missing-data, red-flag,
   reproducibility and customer-claim controls.
6. Product evidence and subject relationships are resolved at runtime and
   never stored in this catalog.

An inherited parameter entry with the same `parameter_id` overrides the base
profile entry. Parameters omitted from a child profile keep their base
applicability and priority.

## Interpretation rules

- `required`: relevant for every product in the profile. Missing evidence
  reduces data confidence.
- `conditional`: relevant only when the product, origin or supply chain meets
  a documented condition. A confirmed non-applicable parameter does not reduce
  confidence.
- `priority`: research and display priority, not a numerical score weight.
- `risk`: contextual risk evidence. It must not be presented as proof that a
  specific product or company caused a violation.
- `assurance`: strength of verification or traceability, not sustainability
  performance by itself.
- `data_confidence`: displayed separately and excluded from E/S/G weighting.
- `score_eligible`: only measured, verified or attributable declared links
  with sufficient confidence may become score inputs.
- `product origin`: does not establish the origin of each commodity.
- `red flag`: a confirmed severe social finding is non-compensatory.

Formula v1.0 remains the active app method. Version `2.0-draft` must pass source
validation, calibration, review and a dedicated publication migration before
it can produce customer-facing scores.

The five scoring-safety gates are `G-LINK-INTEGRITY`, `G-MISSING-DATA`,
`G-RED-FLAG`, `G-SCORE-REPRO` and `G-CLAIM-SAFETY`. They validate
`scoring-controls.yaml` but do not activate methodology 2.0. All new raw
mappings and controls remain `active_in_formula: false` until calibration,
expert review and a publication decision are complete.

## Customer result contract

The first result view shows the overall ESG score, Environmental, Social and
Transparency pillar results, plus separate data confidence. Internally,
Transparency remains the Governance pillar. A health companion indicator is
shown separately and is never included in the ESG total.

The detail view explains factors, evidence scope, source quality, freshness,
missing data, non-applicable parameters and the exact methodology version.

## Validated raw mappings

`AGRIBALYSE 3.2 -> E-GHG-INTENSITY` is the first validated raw mapping. It uses
the official climate-change indicator in `kg CO2e/kg`, retains the AGRIBALYSE
code and DQR and records Open Food Facts as its current retrieval channel.

The mapping has category scope and `active_in_formula: false`. It cannot be
described as a measured product footprint and cannot affect a score until
category resolution, normalization, calibration and review are complete.
