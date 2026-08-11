#!/usr/bin/env ruby

require "date"
require "yaml"

repo_root = File.expand_path("../..", __dir__)
register_path = File.join(repo_root, "docs/project/improvement-register.yaml")
gap_register_path = File.join(repo_root, "docs/project/gap-register.yaml")
risk_register_path = File.join(repo_root, "docs/project/risks.yaml")
compliance_source_path =
  File.join(repo_root, "docs/project/compliance/source-register.yaml")
features_dir = File.join(repo_root, "docs/project/features")
feature_readme_path = File.join(features_dir, "README.md")
violations = []

def load_yaml(path)
  YAML.safe_load(
    File.read(path),
    permitted_classes: [Date],
    aliases: true,
  )
end

unless File.file?(register_path)
  warn "Project control validation failed:"
  warn "- docs/project/improvement-register.yaml: file is missing"
  exit 1
end

register = load_yaml(register_path)
allowed = register.fetch("allowed_values", {})
allowed_layers = Array(allowed["layers"])
allowed_statuses = Array(allowed["statuses"])
allowed_priorities = Array(allowed["priorities"])
allowed_risks = Array(allowed["risks"])
allowed_profiles = Array(allowed["target_profiles"])
improvements = Array(register["improvements"])

required_root_fields = %w[
  schema_version
  last_updated
  owner
  purpose
  allowed_values
  execution_order
  improvements
]
required_root_fields.each do |field|
  violations << "improvement-register.yaml: missing root field #{field}" unless register.key?(field)
end

{
  "layers" => allowed_layers,
  "statuses" => allowed_statuses,
  "priorities" => allowed_priorities,
  "risks" => allowed_risks,
  "target_profiles" => allowed_profiles,
}.each do |field, values|
  if values.empty?
    violations << "improvement-register.yaml: allowed_values.#{field} must not be empty"
  end
end

if improvements.empty?
  violations << "improvement-register.yaml: improvements must not be empty"
end

ids = improvements.map { |item| item["id"] }.compact
id_counts = ids.each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }
duplicates = id_counts.select { |_id, count| count > 1 }.keys
duplicates.each do |id|
  violations << "improvement-register.yaml: duplicate improvement id #{id}"
end

improvements.each_with_index do |item, index|
  location = "improvement-register.yaml: improvements[#{index}]"
  id = item["id"]
  unless id.to_s.match?(/\AIMP-(PROC|COMP|DEV|OPS)-\d{3}\z/)
    violations << "#{location}: invalid id #{id.inspect}"
  end

  %w[title owner rationale next_action].each do |field|
    value = item[field]
    violations << "#{id || location}: #{field} must not be empty" if value.to_s.strip.empty?
  end

  {
    "layer" => allowed_layers,
    "status" => allowed_statuses,
    "priority" => allowed_priorities,
    "risk" => allowed_risks,
    "target_profile" => allowed_profiles,
  }.each do |field, values|
    value = item[field]
    unless values.include?(value)
      violations << "#{id || location}: invalid #{field} #{value.inspect}"
    end
  end

  acceptance_criteria = Array(item["acceptance_criteria"])
  verification = Array(item["verification"])
  evidence = Array(item["evidence"])
  dependencies = Array(item["dependencies"])

  if acceptance_criteria.empty?
    violations << "#{id || location}: acceptance_criteria must not be empty"
  end
  violations << "#{id || location}: verification must not be empty" if verification.empty?

  if %w[review done].include?(item["status"]) && evidence.empty?
    violations << "#{id || location}: #{item['status']} items require evidence"
  end

  evidence.each do |reference|
    next if reference.to_s.match?(%r{\Ahttps://})

    evidence_path = File.join(repo_root, reference.to_s)
    unless File.exist?(evidence_path)
      violations << "#{id || location}: evidence path does not exist: #{reference}"
    end
  end

  dependencies.each do |dependency|
    unless ids.include?(dependency)
      violations << "#{id || location}: unknown dependency #{dependency}"
    end
    if dependency == id
      violations << "#{id || location}: improvement cannot depend on itself"
    end
  end
end

execution_order = Array(register["execution_order"])
if execution_order.empty?
  violations << "improvement-register.yaml: execution_order must not be empty"
end
execution_order.each do |id|
  unless ids.include?(id)
    violations << "improvement-register.yaml: execution_order references unknown id #{id}"
  end
end
execution_counts =
  execution_order.each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }
execution_counts.each do |id, count|
  if count > 1
    violations << "improvement-register.yaml: execution_order repeats #{id}"
  end
end

improvements_by_id = improvements.each_with_object({}) do |item, index|
  index[item["id"]] = item if item["id"]
end
execution_positions = execution_order.each_with_index.to_h
execution_order.each do |id|
  item = improvements_by_id[id]
  next unless item

  if %w[done parked dropped].include?(item["status"])
    violations << "improvement-register.yaml: execution_order includes terminal item #{id}"
  end
  Array(item["dependencies"]).each do |dependency|
    next unless execution_positions.key?(dependency)

    if execution_positions[dependency] >= execution_positions[id]
      violations <<
        "improvement-register.yaml: #{dependency} must precede dependent #{id}"
    end
  end
end

visiting = {}
visited = {}
visit = lambda do |id, path|
  return if visited[id]
  if visiting[id]
    violations << "improvement-register.yaml: dependency cycle #{(path + [id]).join(' -> ')}"
    return
  end

  visiting[id] = true
  item = improvements_by_id[id]
  Array(item && item["dependencies"]).each do |dependency|
    visit.call(dependency, path + [id]) if improvements_by_id.key?(dependency)
  end
  visiting.delete(id)
  visited[id] = true
end
ids.each { |id| visit.call(id, []) }

gap_count = 0
unless File.file?(gap_register_path)
  violations << "docs/project/gap-register.yaml: file is missing"
else
  gap_register = load_yaml(gap_register_path)
  gap_count = Array(gap_register["gaps"]).length

  %w[
    schema_version
    last_assessed
    next_full_review_due
    owner
    method
    assessment_report
    allowed_values
    gaps
  ].each do |field|
    unless gap_register.key?(field)
      violations << "gap-register.yaml: missing root field #{field}"
    end
  end

  %w[method assessment_report].each do |field|
    reference = gap_register[field]
    next if reference.to_s.strip.empty?

    reference_path = File.join(repo_root, reference.to_s)
    unless File.file?(reference_path)
      violations << "gap-register.yaml: #{field} path does not exist: #{reference}"
    end
  end

  begin
    last_assessed = Date.parse(gap_register.fetch("last_assessed").to_s)
    if last_assessed > Date.today
      violations << "gap-register.yaml: last_assessed cannot be in the future"
    end
  rescue KeyError, Date::Error
    violations << "gap-register.yaml: last_assessed must be an ISO date"
  end

  begin
    next_review = Date.parse(gap_register.fetch("next_full_review_due").to_s)
    if next_review < Date.today
      violations <<
        "gap-register.yaml: full lifecycle review overdue since #{next_review}"
    end
  rescue KeyError, Date::Error
    violations << "gap-register.yaml: next_full_review_due must be an ISO date"
  end

  gap_allowed = gap_register.fetch("allowed_values", {})
  gap_domains = Array(gap_allowed["domains"])
  gap_types = Array(gap_allowed["gap_types"])
  gap_statuses = Array(gap_allowed["statuses"])
  gap_priorities = Array(gap_allowed["priorities"])
  gap_profiles = Array(gap_allowed["target_profiles"])

  {
    "domains" => gap_domains,
    "gap_types" => gap_types,
    "statuses" => gap_statuses,
    "priorities" => gap_priorities,
    "target_profiles" => gap_profiles,
  }.each do |field, values|
    if values.empty?
      violations << "gap-register.yaml: allowed_values.#{field} must not be empty"
    end
  end

  risks =
    if File.file?(risk_register_path)
      Array(load_yaml(risk_register_path)["risks"])
    else
      violations << "docs/project/risks.yaml: file is missing"
      []
    end
  risk_ids = risks.map { |risk| risk["id"] }.compact

  sources =
    if File.file?(compliance_source_path)
      Array(load_yaml(compliance_source_path)["sources"])
    else
      violations << "docs/project/compliance/source-register.yaml: file is missing"
      []
    end
  source_ids = sources.map { |source| source["id"] }.compact

  gaps = Array(gap_register["gaps"])
  violations << "gap-register.yaml: gaps must not be empty" if gaps.empty?
  gap_ids = gaps.map { |gap| gap["id"] }.compact
  gap_ids.each_with_object(Hash.new(0)) do |id, counts|
    counts[id] += 1
  end.each do |id, count|
    violations << "gap-register.yaml: duplicate gap id #{id}" if count > 1
  end

  gaps.each_with_index do |gap, index|
    location = "gap-register.yaml: gaps[#{index}]"
    id = gap["id"]
    unless id.to_s.match?(/\AGAP-\d{3}\z/)
      violations << "#{location}: invalid id #{id.inspect}"
    end

    %w[title owner trigger concern].each do |field|
      if gap[field].to_s.strip.empty?
        violations << "#{id || location}: #{field} must not be empty"
      end
    end

    {
      "domain" => gap_domains,
      "gap_type" => gap_types,
      "status" => gap_statuses,
      "priority" => gap_priorities,
      "target_profile" => gap_profiles,
    }.each do |field, values|
      unless values.include?(gap[field])
        violations << "#{id || location}: invalid #{field} #{gap[field].inspect}"
      end
    end

    current_maturity = gap["maturity_current"]
    target_maturity = gap["maturity_target"]
    unless current_maturity.is_a?(Integer) && current_maturity.between?(0, 5)
      violations << "#{id || location}: maturity_current must be an integer from 0 to 5"
    end
    unless target_maturity.is_a?(Integer) && target_maturity.between?(0, 5)
      violations << "#{id || location}: maturity_target must be an integer from 0 to 5"
    end
    if current_maturity.is_a?(Integer) && target_maturity.is_a?(Integer) &&
       target_maturity < current_maturity
      violations << "#{id || location}: maturity_target cannot be below current maturity"
    end

    closure_criteria = Array(gap["closure_criteria"])
    if closure_criteria.length < 3
      violations << "#{id || location}: at least three closure criteria are required"
    end

    mapped_improvements = Array(gap["mapped_improvements"])
    mapped_risks = Array(gap["mapped_risks"])
    source_refs = Array(gap["source_refs"])

    if %w[P0 P1].include?(gap["priority"]) && mapped_improvements.empty?
      violations << "#{id || location}: P0/P1 gaps require an improvement mapping"
    end

    mapped_improvements.each do |improvement_id|
      unless ids.include?(improvement_id)
        violations << "#{id || location}: unknown improvement #{improvement_id}"
      end
    end
    mapped_risks.each do |risk_id|
      unless risk_ids.include?(risk_id)
        violations << "#{id || location}: unknown risk #{risk_id}"
      end
    end
    source_refs.each do |source_id|
      unless source_ids.include?(source_id)
        violations << "#{id || location}: unknown compliance source #{source_id}"
      end
    end

    if gap["status"] == "monitored" && gap["gap_type"] != "trigger_based"
      violations << "#{id || location}: monitored status requires trigger_based type"
    end

    if gap["status"] == "closed"
      if !current_maturity.is_a?(Integer) || current_maturity < 4
        violations << "#{id || location}: closed gaps require maturity_current >= 4"
      end
      evidence = Array(gap["closure_evidence"])
      if evidence.empty?
        violations << "#{id || location}: closed gaps require closure_evidence"
      end
      evidence.each do |reference|
        next if reference.to_s.match?(%r{\Ahttps://})

        evidence_path = File.join(repo_root, reference.to_s)
        unless File.exist?(evidence_path)
          violations << "#{id || location}: closure evidence path does not exist: #{reference}"
        end
      end
    end
  end
end

unless File.file?(feature_readme_path)
  violations << "docs/project/features/README.md: file is missing"
else
  feature_readme = File.read(feature_readme_path)
  state_paths = Dir.glob(File.join(features_dir, "*", "state.yaml")).sort
  state_features = state_paths.map { |path| File.basename(File.dirname(path)) }
  overview_rows =
    feature_readme.scan(/^\| \[([a-z0-9-]+)\]\(([^)]+\/state\.yaml)\) \|/)
  overview_features = overview_rows.map(&:first)

  overview_rows.each do |feature, link|
    expected_link = "#{feature}/state.yaml"
    unless link == expected_link
      violations <<
        "docs/project/features/README.md: #{feature} must link to #{expected_link}"
    end
  end
  overview_features.each_with_object(Hash.new(0)) do |feature, counts|
    counts[feature] += 1
  end.each do |feature, count|
    if count > 1
      violations << "docs/project/features/README.md: duplicate feature row #{feature}"
    end
  end
  (overview_features - state_features).each do |feature|
    violations <<
      "docs/project/features/README.md: #{feature} has no corresponding state.yaml"
  end
  (state_features - overview_features).each do |feature|
    violations << "docs/project/features/README.md: missing feature row #{feature}"
  end

  state_paths.each do |state_path|
    state = load_yaml(state_path)
    feature = state["feature"]
    directory_feature = File.basename(File.dirname(state_path))
    relative_link = "#{feature}/state.yaml"

    if feature != directory_feature
      violations << "#{state_path}: feature must match directory #{directory_feature}"
    end
    unless allowed_statuses.include?(state["status"])
      violations << "#{state_path}: invalid lifecycle status #{state['status'].inspect}"
    end
    progress = state["progress"]
    unless progress.is_a?(Integer) && progress.between?(0, 100)
      violations << "#{state_path}: progress must be an integer from 0 to 100"
    end
    %w[code_locations test_locations].each do |field|
      references = Array(state[field])
      violations << "#{state_path}: #{field} must not be empty" if references.empty?
      references.each do |reference|
        referenced_path = File.join(repo_root, reference.to_s)
        unless File.file?(referenced_path)
          violations << "#{state_path}: #{field} path does not exist: #{reference}"
        end
      end
    end

    expected_row =
      "| [#{feature}](#{relative_link}) | #{state['status']} | " \
      "#{state['progress']}% | #{state['phase']} | #{state['sprint']} |"

    unless feature_readme.include?(expected_row)
      violations << "docs/project/features/README.md: expected row #{expected_row.inspect}"
    end
  end
end

if violations.empty?
  puts(
    "Project control traceability OK: " \
    "#{improvements.length} improvements, " \
    "#{execution_order.length} active sequence items, " \
    "#{gap_count} lifecycle gaps, " \
    "#{Dir.glob(File.join(features_dir, '*', 'state.yaml')).length} feature states",
  )
  exit 0
end

warn "Project control validation failed:"
violations.each { |violation| warn "- #{violation}" }
exit 1
