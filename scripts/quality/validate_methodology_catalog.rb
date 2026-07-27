#!/usr/bin/env ruby

require "yaml"

repo_root = File.expand_path("../..", __dir__)
catalog_root = File.join(
  repo_root,
  "docs",
  "project",
  "methodology-catalog"
)
parameter_path = File.join(catalog_root, "parameters.yaml")
profile_paths = Dir.glob(File.join(catalog_root, "profiles", "*.yaml")).sort
mapping_paths = Dir.glob(
  File.join(catalog_root, "source-mappings", "*.yaml")
).sort
source_register_path = File.join(
  repo_root,
  "docs",
  "project",
  "data",
  "source-register.yaml"
)
violations = []

def load_yaml(path)
  YAML.safe_load(
    File.read(path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false
  )
end

unless File.exist?(parameter_path)
  violations << "Missing methodology parameter catalog"
end
violations << "No methodology profiles found" if profile_paths.empty?
violations << "No methodology source mappings found" if mapping_paths.empty?
unless File.exist?(source_register_path)
  violations << "Missing ESG data source register"
end

if violations.empty?
  catalog = load_yaml(parameter_path)
  parameters = catalog.fetch("parameters", [])
  parameter_ids = parameters.map { |parameter| parameter["id"] }

  violations << "Catalog status must be draft" unless catalog["status"] == "draft"
  unless catalog["methodology_version"] == "2.0-draft"
    violations << "Catalog methodology_version must be 2.0-draft"
  end
  if parameter_ids.length != parameter_ids.uniq.length
    violations << "Duplicate parameter IDs found"
  end

  required_parameter_fields = %w[
    id
    pillar
    display_name_de
    display_name_en
    description_de
    description_en
    scope
    result_kind
    unit
    missing_behavior
    customer_claim_rule
    status
  ]
  allowed_pillars = %w[
    environmental
    social
    governance
    data_confidence
  ]
  allowed_scopes = %w[
    product
    category
    commodity_country
    company
    supply_chain
  ]
  allowed_result_kinds = %w[performance risk assurance confidence]
  allowed_missing_behaviors = %w[
    reduce_confidence
    not_applicable_when_out_of_scope
    block_factor_assessment
  ]
  allowed_claim_rules = %w[
    evidence_only
    risk_not_product_finding
    assurance_only
    confidence_only
  ]

  parameters.each do |parameter|
    parameter_id = parameter["id"] || "<missing-id>"
    missing_fields = required_parameter_fields.reject do |field|
      value = parameter[field]
      !value.nil? && !value.to_s.empty?
    end
    unless missing_fields.empty?
      violations << "#{parameter_id}: missing #{missing_fields.join(', ')}"
    end
    unless parameter_id.match?(/\A[ESGD]-[A-Z0-9-]+\z/)
      violations << "#{parameter_id}: invalid parameter ID"
    end
    unless allowed_pillars.include?(parameter["pillar"])
      violations << "#{parameter_id}: invalid pillar"
    end
    unless allowed_scopes.include?(parameter["scope"])
      violations << "#{parameter_id}: invalid scope"
    end
    unless allowed_result_kinds.include?(parameter["result_kind"])
      violations << "#{parameter_id}: invalid result_kind"
    end
    unless allowed_missing_behaviors.include?(parameter["missing_behavior"])
      violations << "#{parameter_id}: invalid missing_behavior"
    end
    unless allowed_claim_rules.include?(parameter["customer_claim_rule"])
      violations << "#{parameter_id}: invalid customer_claim_rule"
    end
    unless parameter["status"] == "draft"
      violations << "#{parameter_id}: parameter must remain draft"
    end
    if parameter.key?("weight")
      violations << "#{parameter_id}: numerical weights are not approved"
    end
    if parameter["pillar"] == "data_confidence" &&
       parameter["result_kind"] != "confidence"
      violations << "#{parameter_id}: data confidence must use confidence result"
    end
    if parameter["pillar"] != "data_confidence" &&
       parameter["result_kind"] == "confidence"
      violations << "#{parameter_id}: confidence must be outside ESG pillars"
    end
    if parameter["scope"] == "commodity_country" &&
       parameter["result_kind"] == "risk" &&
       parameter["customer_claim_rule"] != "risk_not_product_finding"
      violations << "#{parameter_id}: contextual risk needs non-accusatory claim rule"
    end
  end

  profiles = profile_paths.map { |path| [path, load_yaml(path)] }
  profile_ids = profiles.map { |_path, profile| profile["profile_id"] }
  if profile_ids.length != profile_ids.uniq.length
    violations << "Duplicate profile IDs found"
  end
  unless profile_ids.include?("food-base")
    violations << "Missing food-base profile"
  end

  profiles.each do |path, profile|
    relative_path = path.delete_prefix("#{repo_root}/")
    profile_id = profile["profile_id"] || relative_path
    required_profile_fields = %w[
      schema_version
      profile_id
      methodology_version
      status
      display_name_de
      display_name_en
      description_de
      description_en
      parameters
      weighting
    ]
    missing_fields = required_profile_fields.reject do |field|
      !profile[field].nil?
    end
    unless missing_fields.empty?
      violations << "#{profile_id}: missing #{missing_fields.join(', ')}"
    end
    unless profile["methodology_version"] == catalog["methodology_version"]
      violations << "#{profile_id}: methodology version mismatch"
    end
    unless profile["status"] == "draft"
      violations << "#{profile_id}: profile must remain draft"
    end
    parent_id = profile["extends"]
    if parent_id && !profile_ids.include?(parent_id)
      violations << "#{profile_id}: unknown parent profile #{parent_id}"
    end
    if parent_id == profile_id
      violations << "#{profile_id}: profile cannot extend itself"
    end
    unless profile.dig("weighting", "status") == "deferred"
      violations << "#{profile_id}: weighting must be deferred"
    end

    entries = profile.fetch("parameters", [])
    entry_ids = entries.map { |entry| entry["parameter_id"] }
    if entry_ids.length != entry_ids.uniq.length
      violations << "#{profile_id}: duplicate parameter references"
    end
    entries.each do |entry|
      parameter_id = entry["parameter_id"]
      unless parameter_ids.include?(parameter_id)
        violations << "#{profile_id}: unknown parameter #{parameter_id}"
      end
      unless %w[required conditional not_applicable].include?(
        entry["applicability"]
      )
        violations << "#{profile_id}/#{parameter_id}: invalid applicability"
      end
      unless %w[high medium low].include?(entry["priority"])
        violations << "#{profile_id}/#{parameter_id}: invalid priority"
      end
      if entry.key?("weight")
        violations << "#{profile_id}/#{parameter_id}: weights are not approved"
      end
    end
  end

  parent_by_profile = profiles.to_h do |_path, profile|
    [profile["profile_id"], profile["extends"]]
  end
  profile_ids.each do |profile_id|
    seen = []
    current = profile_id
    while current
      if seen.include?(current)
        violations << "#{profile_id}: inheritance cycle detected"
        break
      end
      seen << current
      current = parent_by_profile[current]
    end
  end

  source_register = load_yaml(source_register_path)
  sources = source_register.fetch("sources", [])
  source_by_id = sources.to_h { |source| [source["id"], source] }
  mapping_count = 0

  mapping_paths.each do |path|
    mapping_set = load_yaml(path)
    mapping_set_id = mapping_set["mapping_set_id"] || File.basename(path)
    source_id = mapping_set["source_id"]
    retrieval_channel_id = mapping_set["retrieval_channel_source_id"]
    source = source_by_id[source_id]
    retrieval_channel = source_by_id[retrieval_channel_id]
    mappings = mapping_set.fetch("mappings", [])
    mapping_count += mappings.length

    unless mapping_set["methodology_version"] == catalog["methodology_version"]
      violations << "#{mapping_set_id}: methodology version mismatch"
    end
    unless mapping_set["status"] == "validated"
      violations << "#{mapping_set_id}: mapping set must be validated"
    end
    unless mapping_set["active_in_formula"] == false
      violations << "#{mapping_set_id}: draft mapping cannot be score-active"
    end
    unless source && source["status"] == "active"
      violations << "#{mapping_set_id}: source #{source_id} is not active"
    end
    unless retrieval_channel && retrieval_channel["status"] == "active"
      violations <<(
        "#{mapping_set_id}: retrieval channel #{retrieval_channel_id} is not active"
      )
    end
    if source && mapping_set.dig("source_record", "license") !=
       source.dig("license", "database")
      violations << "#{mapping_set_id}: source license mismatch"
    end
    if mappings.empty?
      violations << "#{mapping_set_id}: no parameter mappings"
    end

    mapping_ids = mappings.map { |mapping| mapping["id"] }
    if mapping_ids.length != mapping_ids.uniq.length
      violations << "#{mapping_set_id}: duplicate mapping IDs"
    end

    mappings.each do |mapping|
      mapping_id = mapping["id"] || "#{mapping_set_id}/<missing-id>"
      required_mapping_fields = %w[
        id
        parameter_id
        status
        mapping_kind
        source_field
        source_unit
        evidence_scope
        delivery_paths
        applicability
        evidence_requirements
        customer_claim_rule
        active_in_formula
        activation_requires
        reference_records
      ]
      missing_fields = required_mapping_fields.reject do |field|
        !mapping[field].nil?
      end
      unless missing_fields.empty?
        violations << "#{mapping_id}: missing #{missing_fields.join(', ')}"
      end
      unless parameter_ids.include?(mapping["parameter_id"])
        violations << "#{mapping_id}: unknown parameter"
      end
      unless mapping["status"] == "validated"
        violations << "#{mapping_id}: mapping must be validated"
      end
      unless mapping["mapping_kind"] == "direct_raw_indicator"
        violations << "#{mapping_id}: only direct raw mappings are approved"
      end
      unless allowed_scopes.include?(mapping["evidence_scope"])
        violations << "#{mapping_id}: invalid evidence scope"
      end
      unless mapping["active_in_formula"] == false
        violations << "#{mapping_id}: mapping cannot be score-active"
      end
      if mapping["evidence_scope"] == "category" &&
         mapping["customer_claim_rule"] !=
           "category_proxy_not_product_measurement"
        violations << "#{mapping_id}: category proxy claim rule missing"
      end

      mapped_profiles = mapping.dig("applicability", "profiles") || []
      unknown_profiles = mapped_profiles - profile_ids
      unless unknown_profiles.empty?
        violations <<(
          "#{mapping_id}: unknown profiles #{unknown_profiles.join(', ')}"
        )
      end
      if mapped_profiles.empty?
        violations << "#{mapping_id}: no applicable profiles"
      end

      delivery_paths = mapping["delivery_paths"] || {}
      %w[value record_id source_version source_quality].each do |field|
        paths = delivery_paths[field]
        unless paths.is_a?(Array) && !paths.empty?
          violations << "#{mapping_id}: missing delivery path #{field}"
        end
      end

      reference_records = mapping["reference_records"] || []
      if reference_records.empty?
        violations << "#{mapping_id}: no reference records"
      end
      reference_records.each do |record|
        unless record["code"].to_s.match?(/\A\d+\z/)
          violations << "#{mapping_id}: invalid reference code"
        end
        value = record["climate_change_kg_co2e_per_kg"]
        unless value.is_a?(Numeric) && value.positive?
          violations << "#{mapping_id}: invalid climate reference value"
        end
        dqr = record["dqr"]
        unless dqr.is_a?(Numeric) && dqr.between?(1, 5)
          violations << "#{mapping_id}: invalid DQR reference value"
        end
      end
    end
  end
end

if violations.empty?
  puts(
    "Methodology catalog OK: #{parameter_ids.length} parameters, " \
    "#{profile_paths.length} profiles, #{mapping_count} validated raw mapping(s), " \
    "weights deferred"
  )
  exit 0
end

warn "Methodology catalog validation failed:"
violations.each { |violation| warn "- #{violation}" }
exit 1
