#!/usr/bin/env ruby

require "yaml"

repo_root = File.expand_path("../..", __dir__)
controls_path = File.join(
  repo_root,
  "docs",
  "project",
  "methodology-catalog",
  "scoring-controls.yaml"
)
parameters_path = File.join(
  repo_root,
  "docs",
  "project",
  "methodology-catalog",
  "parameters.yaml"
)
mapping_paths = Dir.glob(
  File.join(
    repo_root,
    "docs",
    "project",
    "methodology-catalog",
    "source-mappings",
    "*.yaml"
  )
)
migration_sql = Dir.glob(
  File.join(repo_root, "supabase", "migrations", "*.sql")
).sort.map { |path| File.read(path) }.join("\n").downcase
relationship_model_path = File.join(
  repo_root,
  "esg_app",
  "lib",
  "models",
  "esg_relationship.dart"
)
product_model_path = File.join(
  repo_root,
  "esg_app",
  "lib",
  "models",
  "product.dart"
)
score_model_path = File.join(
  repo_root,
  "esg_app",
  "lib",
  "models",
  "esg_score.dart"
)
score_widgets_path = File.join(
  repo_root,
  "esg_app",
  "lib",
  "widgets",
  "score_widgets.dart"
)
readme_path = File.join(repo_root, "README.md")

def load_yaml(path)
  YAML.safe_load(
    File.read(path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false
  )
end

gate = ARGV.each_cons(2).find { |left, _right| left == "--gate" }&.last
allowed_gates = %w[
  link-integrity
  missing-data
  red-flag
  score-reproducibility
  claim-safety
]

unless allowed_gates.include?(gate)
  warn "Usage: ruby scripts/quality/validate_scoring_safety.rb --gate " \
       "{#{allowed_gates.join('|')}}"
  exit 2
end

required_files = [
  controls_path,
  parameters_path,
  relationship_model_path,
  product_model_path,
  score_model_path,
  score_widgets_path,
  readme_path,
]
missing_files = required_files.reject { |path| File.exist?(path) }
unless missing_files.empty?
  missing_files.each { |path| warn "Missing required file: #{path}" }
  exit 1
end

controls = load_yaml(controls_path)
catalog = load_yaml(parameters_path)
relationship_model = File.read(relationship_model_path)
product_model = File.read(product_model_path)
score_model = File.read(score_model_path)
score_widgets = File.read(score_widgets_path)
customer_facing_content = [
  score_model,
  score_widgets,
  File.read(readme_path),
].join("\n").downcase
violations = []

unless controls["methodology_version"] == "2.0-draft"
  violations << "Scoring controls must target methodology 2.0-draft"
end
unless controls["status"] == "draft" && controls["active_in_formula"] == false
  violations << "Uncalibrated scoring controls must remain inactive and draft"
end

case gate
when "link-integrity"
  required_tables = %w[
    traceability_entities
    traceability_entity_identifiers
    traceability_relationships
  ]
  required_tables.each do |table|
    unless migration_sql.include?("create table if not exists public.#{table}")
      violations << "Missing public.#{table}"
    end
  end

  required_fields = %w[
    source_id
    source_record_id
    retrieved_at
    confidence
    assertion_class
    evidence_ids
  ]
  configured_fields = controls.dig(
    "link_integrity",
    "every_relationship_requires"
  ) || []
  missing = required_fields - configured_fields
  violations << "Relationship controls missing #{missing.join(', ')}" unless (
    missing.empty?
  )

  required_relationships = controls.dig(
    "link_integrity",
    "contextual_commodity_country_risk_requires"
  )
  unless required_relationships == %w[contains_commodity commodity_has_origin]
    violations << "Commodity-country risk needs both commodity and origin links"
  end
  unless controls.dig(
    "link_integrity",
    "unbound_product_origin_is_not_commodity_origin"
  ) == true
    violations << "Unbound product origins must not become commodity origins"
  end

  %w[
    ESGRelationship
    assertionClass
    confidence
    evidenceIds
    scoreEligible
    supportsContextualRisk
  ].each do |marker|
    violations << "Dart relationship model missing #{marker}" unless (
      relationship_model.include?(marker)
    )
  end
  unless product_model.include?("hasScoreEligibleCommodityOrigin")
    violations << "Product model lacks complete commodity-origin chain check"
  end
  unless product_model.include?("hasScoreEligibleLegalEntity")
    violations << "Product model lacks legal-entity eligibility check"
  end
when "missing-data"
  missing_controls = controls.fetch("missing_data", {})
  %w[no_positive_imputation no_neutral_imputation no_zero_imputation].each do |key|
    violations << "#{key} must be true" unless missing_controls[key] == true
  end
  unless missing_controls["required_link_missing_behavior"] ==
         "block_factor_assessment"
    violations << "A missing required link must block factor assessment"
  end
  unless missing_controls["customer_state_when_score_blocked"] ==
         "data_incomplete"
    violations << "Blocked assessments must use data_incomplete"
  end

  allowed_missing_behaviors = %w[
    reduce_confidence
    not_applicable_when_out_of_scope
    block_factor_assessment
  ]
  catalog.fetch("parameters", []).each do |parameter|
    unless allowed_missing_behaviors.include?(parameter["missing_behavior"])
      violations << "#{parameter['id']}: invalid missing behavior"
    end
  end
  unless score_model.include?("dataIncomplete")
    violations << "App score model lacks an explicit incomplete-data state"
  end
when "red-flag"
  red_flags = controls.fetch("red_flags", {})
  violations << "Red flags must be non-compensatory" unless (
    red_flags["non_compensatory"] == true
  )
  violations << "Contextual risk must not be a confirmed finding" unless (
    red_flags["contextual_risk_is_not_confirmed_finding"] == true
  )
  severe = red_flags.fetch("confirmed_severe_social_finding", {})
  unless severe["publication_decision"] ==
         "block_pending_methodology_review"
    violations << "Severe confirmed findings must block score publication"
  end
  unless severe["may_be_offset_by_other_pillars"] == false
    violations << "Severe social findings must not be offset"
  end
  unless migration_sql.include?("red_flag_evidence_ids")
    violations << "Score snapshots do not retain red-flag evidence"
  end
when "score-reproducibility"
  required_snapshot_fields = controls.dig(
    "reproducibility",
    "required_snapshot_fields"
  ) || []
  expected_fields = %w[
    formula_version
    input_fingerprint
    evidence_ids
    relationship_ids
    data_confidence_score
    red_flag_evidence_ids
    calculated_at
  ]
  missing = expected_fields - required_snapshot_fields
  violations << "Snapshot controls missing #{missing.join(', ')}" unless (
    missing.empty?
  )
  expected_fields.each do |field|
    violations << "Database score snapshot missing #{field}" unless (
      migration_sql.include?(field)
    )
  end
  unless controls.dig("reproducibility", "deterministic_formula_required") == true
    violations << "Deterministic formula requirement missing"
  end
  unless score_model.include?("formulaVersion")
    violations << "App score output lacks a formula version"
  end
when "claim-safety"
  claims = controls.fetch("claims", {})
  %w[
    score_is_not_certification
    score_is_not_legal_compliance_determination
  ].each do |key|
    violations << "#{key} must be true" unless claims[key] == true
  end
  unless claims["contextual_risk_label"] == "risk_not_product_finding"
    violations << "Contextual risk claim label is unsafe"
  end
  unless claims["category_proxy_label"] ==
         "category_average_not_product_measurement"
    violations << "Category proxy claim label is unsafe"
  end
  if claims.fetch("prohibited_customer_phrases", []).empty?
    violations << "No prohibited customer claim classes configured"
  end
  prohibited_patterns = [
    /garantiert(?:e[rs]?)?\s+esg/,
    /esg[- ]compliant/,
    /frei von kinderarbeit/,
    /gemessener produktfu(?:\u00df|ss)abdruck/,
  ]
  prohibited_patterns.each do |pattern|
    if customer_facing_content.match?(pattern)
      violations << "Customer-facing content contains prohibited claim #{pattern}"
    end
  end
  unless score_widgets.include?("Orientierung, keine ") &&
         score_widgets.include?("Zertifizierung")
    violations << "In-app score disclaimer is missing"
  end
  if score_model.include?("return 'Empfehlung'")
    violations << "Heuristic MVP score must not issue an unconditional recommendation"
  end

  catalog.fetch("parameters", []).each do |parameter|
    next unless parameter["scope"] == "commodity_country"
    next unless parameter["result_kind"] == "risk"
    unless parameter["customer_claim_rule"] == "risk_not_product_finding"
      violations << "#{parameter['id']}: contextual risk claim is unsafe"
    end
  end
  mapping_paths.each do |path|
    mapping_set = load_yaml(path)
    mapping_set.fetch("mappings", []).each do |mapping|
      next unless mapping["evidence_scope"] == "category"
      unless mapping["customer_claim_rule"] ==
             "category_proxy_not_product_measurement"
        violations << "#{mapping['id']}: category proxy claim is unsafe"
      end
    end
  end
end

if violations.empty?
  puts "Scoring safety OK: #{gate} controls verified for methodology 2.0-draft"
  exit 0
end

warn "Scoring safety validation failed for #{gate}:"
violations.each { |violation| warn "- #{violation}" }
exit 1
