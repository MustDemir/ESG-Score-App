#!/usr/bin/env ruby

require "date"
require "yaml"

repo_root = File.expand_path("../..", __dir__)
register_path = File.join(repo_root, "docs/project/improvement-register.yaml")
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
execution_order.each do |id|
  item = improvements_by_id[id]
  next unless item

  if %w[done parked dropped].include?(item["status"])
    violations << "improvement-register.yaml: execution_order includes terminal item #{id}"
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

unless File.file?(feature_readme_path)
  violations << "docs/project/features/README.md: file is missing"
else
  feature_readme = File.read(feature_readme_path)
  state_paths = Dir.glob(File.join(features_dir, "*", "state.yaml")).sort
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
    "#{Dir.glob(File.join(features_dir, '*', 'state.yaml')).length} feature states",
  )
  exit 0
end

warn "Project control validation failed:"
violations.each { |violation| warn "- #{violation}" }
exit 1
