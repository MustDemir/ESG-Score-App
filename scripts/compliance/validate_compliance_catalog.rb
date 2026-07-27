#!/usr/bin/env ruby
# Validate the Apple compliance catalog and its cross-artifact traceability.

require "date"
require "set"
require "yaml"

root = File.expand_path("../..", __dir__)
profile = ENV.fetch("COMPLIANCE_PROFILE", "development")
profiles = %w[development release_candidate submission]
errors = []
warnings = []

unless profiles.include?(profile)
  warn "Invalid COMPLIANCE_PROFILE: #{profile}"
  exit 2
end

load_yaml = lambda do |path|
  YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
rescue StandardError => e
  errors << "#{path}: invalid YAML: #{e.message}"
  {}
end

source_path = File.join(root, "docs/project/compliance/source-register.yaml")
source_register = load_yaml.call(source_path)
sources = Array(source_register["sources"])
source_ids = sources.map { |source| source["id"] }.compact.to_set

%w[schema_version last_verified next_review_due review_owner sources].each do |field|
  errors << "source-register.yaml: missing #{field}" unless source_register.key?(field)
end

sources.each do |source|
  %w[id authority title version normative_weight scope].each do |field|
    errors << "source-register.yaml: source #{source['id'] || '<unknown>'} missing #{field}" unless source[field]
  end
  unless source["url"] || source["path"]
    errors << "source-register.yaml: source #{source['id']} needs url or path"
  end
end

begin
  next_review = Date.parse(source_register.fetch("next_review_due").to_s)
  if Date.today > next_review
    message = "source register review overdue since #{next_review}"
    profile == "development" ? warnings << message : errors << message
  end
rescue StandardError
  errors << "source-register.yaml: next_review_due must be an ISO date"
end

requirement_paths = Dir[File.join(root, "docs/project/requirements/R-AS-*.yaml")].sort
gate_paths = Dir[File.join(root, "docs/project/gate-definitions/apple/G-AS-*.yaml")].sort
requirements = requirement_paths.to_h { |path| [File.basename(path, ".yaml"), load_yaml.call(path)] }
gates = gate_paths.to_h { |path| [File.basename(path, ".yaml"), load_yaml.call(path)] }

expected_gates = %w[
  G-AS-BUILD-INTEGRITY
  G-AS-PRIVACY
  G-AS-CAMERA
  G-AS-METADATA
  G-AS-REVIEW-READINESS
  G-AS-CLAIMS-TRANSPARENCY
  G-AS-THIRD-PARTY-RIGHTS
  G-AS-SUPPORT-IDENTITY
].sort

errors << "Apple gate catalog must contain exactly the eight approved groups" unless gates.keys.sort == expected_gates

requirement_fields = %w[
  id title kontrollmechanismus lifecycle_phase governance_dimension must_should
  applicability activation_condition verification source_type description
  evidence_expected acceptance_criteria linked_gates deployer_implication
  audit_trigger source_refs phase
]

requirements.each do |file_id, requirement|
  requirement_fields.each do |field|
    value = requirement[field]
    errors << "#{file_id}: missing or empty #{field}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end
  errors << "#{file_id}: id must match filename" unless requirement["id"] == file_id
  errors << "#{file_id}: must_should must be MUST or SHOULD" unless %w[MUST SHOULD].include?(requirement["must_should"])
  errors << "#{file_id}: applicability must be always or conditional" unless %w[always conditional].include?(requirement["applicability"])
  errors << "#{file_id}: verification must be AUTO, HYBRID or MANUAL" unless %w[AUTO HYBRID MANUAL].include?(requirement["verification"])

  Array(requirement["source_refs"]).each do |source_id|
    errors << "#{file_id}: unknown source #{source_id}" unless source_ids.include?(source_id)
  end

  Array(requirement["linked_gates"]).each do |gate_id|
    errors << "#{file_id}: linked gate #{gate_id} does not exist" unless gates.key?(gate_id)
  end
end

gate_fields = %w[
  id name dimension lifecycle_phase source_type trigger automation policy_checks
  criteria evidence_required decision enforcement owner audit_trail waiver links sources notes
]

gates.each do |file_id, gate|
  gate_fields.each do |field|
    value = gate[field]
    errors << "#{file_id}: missing or empty #{field}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end
  errors << "#{file_id}: id must match filename" unless gate["id"] == file_id
  errors << "#{file_id}: automation must be AUTO or HYBRID" unless %w[AUTO HYBRID].include?(gate["automation"])
  errors << "#{file_id}: decision must be a real action" unless %w[block warn manual_review].include?(gate["decision"])

  enforcement = gate.fetch("enforcement", {})
  profiles.each do |required_profile|
    errors << "#{file_id}: enforcement missing #{required_profile}" unless enforcement.key?(required_profile)
  end

  gate_requirements = Array(gate.dig("links", "requirements"))
  gate_requirements.each do |requirement_id|
    requirement = requirements[requirement_id]
    if requirement.nil?
      errors << "#{file_id}: requirement #{requirement_id} does not exist"
    elsif !Array(requirement["linked_gates"]).include?(file_id)
      errors << "#{file_id}: reverse link missing in #{requirement_id}"
    end
  end

  Array(gate["sources"]).each do |source_id|
    errors << "#{file_id}: unknown source #{source_id}" unless source_ids.include?(source_id)
  end

  Array(gate["policy_checks"]).each do |policy_name|
    policy_path = File.join(root, "docs/project/policies/apple/production/#{policy_name}.rego")
    errors << "#{file_id}: policy file missing #{policy_path}" unless File.file?(policy_path)
  end

  unless gate.dig("audit_trail", "enabled") == true && gate.dig("audit_trail", "evidence_store_ref")
    errors << "#{file_id}: audit trail is incomplete"
  end
end

if errors.empty?
  puts "Compliance catalog valid: #{requirements.length} requirements, #{gates.length} Apple gates, #{sources.length} sources"
  warnings.each { |message| puts "WARN: #{message}" }
  exit 0
end

errors.each { |message| warn "ERROR: #{message}" }
warnings.each { |message| warn "WARN: #{message}" }
warn "Compliance catalog invalid: #{errors.length} error(s)"
exit 1
