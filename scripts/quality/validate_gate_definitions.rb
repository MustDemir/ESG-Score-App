#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "optparse"
require "set"
require "time"
require "yaml"

class GateDefinitionValidator
  CANONICAL_PROFILE = "scanfair-gate-v1"
  GATE_ID_PATTERN = /\AG-[A-Z0-9-]+\z/
  CORE_ALIASES = {
    "trigger" => %w[trigger],
    "criteria" => %w[criteria policy_checks],
    "artifacts" => %w[artifacts evidence_required],
    "decision" => %w[decision],
    "owner" => %w[owner],
    "audit" => %w[audit audit_trail],
    "waiver" => %w[waiver],
  }.freeze

  attr_reader :violations, :warnings, :report

  def initialize(repo_root:, report_path: ".quality/gate-definitions/report.json")
    @repo_root = File.expand_path(repo_root)
    @report_path = report_path
    @violations = []
    @warnings = []
    @gate_results = []
  end

  def run
    load_control_data
    validate_schema
    gate_paths.each { |path| validate_gate(path) }
    build_report
    write_report
    violations.empty?
  end

  private

  def absolute(relative)
    File.join(@repo_root, relative)
  end

  def relative(path)
    path.delete_prefix("#{@repo_root}#{File::SEPARATOR}")
  end

  def load_yaml(relative_path)
    YAML.safe_load(
      File.read(absolute(relative_path), encoding: "UTF-8"),
      permitted_classes: [Date, Time],
      aliases: true,
    ) || {}
  rescue Errno::ENOENT
    violations << "#{relative_path}: file is missing"
    {}
  rescue Psych::SyntaxError => error
    violations << "#{relative_path}: invalid YAML: #{error.message.lines.first.strip}"
    {}
  end

  def load_control_data
    @schema = load_yaml("docs/project/gate-definitions/gate-definition-schema.yaml")
    source_register = load_yaml("docs/project/compliance/source-register.yaml")
    @source_ids = Array(source_register["sources"]).map { |source| source["id"] }.compact.to_set
    @requirement_ids = Dir[absolute("docs/project/requirements/R-*.yaml")]
      .map { |path| File.basename(path, ".yaml") }.to_set
    @improvement_ids = register_ids("docs/project/improvement-register.yaml", "improvements")
    @gap_ids = register_ids("docs/project/gap-register.yaml", "gaps")
    @risk_ids = register_ids("docs/project/risks.yaml", "risks")
    @adr_ids = Dir[absolute("docs/project/decisions/*.yaml")]
      .map { |path| File.basename(path).split("-", 2).first }.to_set
  end

  def register_ids(relative_path, root_key)
    data = load_yaml(relative_path)
    Array(data[root_key]).map { |record| record["id"] }.compact.to_set
  end

  def gate_paths
    Dir[absolute("docs/project/gate-definitions/{local,apple}/*.yaml")].sort
  end

  def validate_schema
    label = "gate-definition-schema.yaml"
    unless @schema["schema_version"] == "1.0" && @schema["profile"] == CANONICAL_PROFILE
      violations << "#{label}: expected schema version 1.0 and profile #{CANONICAL_PROFILE}"
    end
    required = Array(@schema.dig("canonical_metadata", "required"))
    CORE_ALIASES.each_key do |field|
      violations << "#{label}: canonical required metadata missing #{field}" unless required.include?(field)
    end
    rules = Array(@schema["canonical_rules"])
    violations << "#{label}: canonical semantic rules must not be empty" if rules.empty?
  end

  def validate_gate(path)
    file = relative(path)
    before = violations.length
    gate = YAML.safe_load(
      File.read(path, encoding: "UTF-8"),
      permitted_classes: [Date, Time],
      aliases: true,
    ) || {}
    gate_id = gate["id"] || File.basename(path, ".yaml")

    validate_identity(gate, file)
    validate_core_attributes(gate, file)
    validate_sources(gate, file)
    validate_canonical(gate, file) if gate["schema_profile"] == CANONICAL_PROFILE

    if gate["schema_profile"].nil?
      warnings << "#{file}: accepted through an explicit legacy compatibility profile"
    elsif gate["schema_profile"] != CANONICAL_PROFILE
      violations << "#{file}: unsupported schema_profile #{gate['schema_profile'].inspect}"
    end

    @gate_results << {
      "id" => gate_id,
      "schema_profile" => gate["schema_profile"] || legacy_profile(file),
      "status" => violations.length == before ? "PASS" : "FAIL",
    }
  rescue Psych::SyntaxError => error
    violations << "#{file}: invalid YAML: #{error.message.lines.first.strip}"
  end

  def legacy_profile(file)
    file.include?("/apple/") ? "legacy_apple_v1" : "legacy_local_v0"
  end

  def validate_identity(gate, file)
    expected = File.basename(file, ".yaml")
    id = gate["id"]
    violations << "#{file}: id must match filename #{expected}" unless id == expected
    violations << "#{file}: invalid gate id #{id.inspect}" unless id.to_s.match?(GATE_ID_PATTERN)
    title = gate["title"] || gate["name"]
    violations << "#{file}: missing title or name" if blank?(title)
  end

  def validate_core_attributes(gate, file)
    CORE_ALIASES.each do |core, aliases|
      value = aliases.map { |field| gate[field] }.compact.first
      violations << "#{file}: missing seven-attribute core field #{core}" if blank?(value)
    end
  end

  def validate_sources(gate, file)
    Array(gate["sources"]).each do |source|
      next if @source_ids.include?(source)
      source_path = source.to_s.split("#", 2).first
      next if File.exist?(absolute(source_path))
      if gate["schema_profile"].nil? && source.to_s.match?(/\Ahttps:\/\//)
        warnings << "#{file}: legacy direct HTTPS source should migrate to the source register"
        next
      end

      violations << "#{file}: unknown source #{source.inspect}"
    end
  end

  def validate_canonical(gate, file)
    required = Array(@schema.dig("canonical_metadata", "required"))
    required.each do |field|
      violations << "#{file}: canonical metadata missing #{field}" if !gate.key?(field) || blank?(gate[field], allow_empty: allowed_empty?(field))
    end
    return unless gate["schema_version"] == "1.0"

    allowed = @schema.dig("canonical_metadata", "allowed_values") || {}
    validate_allowed(gate, file, "status", allowed["status"])
    validate_allowed(gate, file, "automation", allowed["automation"])
    validate_profiles(gate, file, allowed)
    validate_triggers(gate, file)
    validate_criteria(gate, file, allowed)
    validate_artifacts(gate, file, allowed)
    validate_decision(gate, file)
    validate_audit(gate, file)
    validate_waiver(gate, file)
    validate_links(gate, file)
    violations << "#{file}: canonical sources must not be empty" if Array(gate["sources"]).empty?
  end

  def allowed_empty?(field)
    field == "links"
  end

  def validate_allowed(gate, file, field, values)
    return if Array(values).include?(gate[field])

    violations << "#{file}: #{field} must be one of #{Array(values).join(', ')}"
  end

  def validate_profiles(gate, file, allowed)
    profiles = Array(gate["profile_scope"])
    invalid = profiles - Array(allowed["profiles"])
    violations << "#{file}: profile_scope must not be empty" if profiles.empty?
    violations << "#{file}: invalid profiles #{invalid.join(', ')}" unless invalid.empty?

    enforcement = gate["enforcement"] || {}
    profiles.each do |profile|
      value = enforcement[profile]
      unless Array(allowed["enforcement"]).include?(value)
        violations << "#{file}: enforcement.#{profile} is missing or invalid"
      end
    end
  end

  def validate_triggers(gate, file)
    triggers = gate["trigger"]
    unless triggers.is_a?(Array) && !triggers.empty? && triggers.all? { |item| item.to_s.match?(/\A[a-z0-9_]+\z/) }
      violations << "#{file}: canonical trigger must be a non-empty snake_case list"
    end
  end

  def validate_criteria(gate, file, allowed)
    criteria = gate["criteria"]
    unless criteria.is_a?(Array) && !criteria.empty?
      violations << "#{file}: canonical criteria must be a non-empty list"
      return
    end

    ids = Set.new
    verification_types = []
    criteria.each_with_index do |criterion, index|
      label = "#{file}: criteria[#{index}]"
      unless criterion.is_a?(Hash)
        violations << "#{label} must be an object"
        next
      end
      %w[id statement verification severity].each do |field|
        violations << "#{label} missing #{field}" if blank?(criterion[field])
      end
      if ids.include?(criterion["id"])
        violations << "#{label} duplicate criterion id #{criterion['id']}"
      end
      ids << criterion["id"]
      unless Array(allowed["verification"]).include?(criterion["verification"])
        violations << "#{label} invalid verification #{criterion['verification'].inspect}"
      end
      unless Array(allowed["severity"]).include?(criterion["severity"])
        violations << "#{label} invalid severity #{criterion['severity'].inspect}"
      end
      verification_types << criterion["verification"]
    end

    automation = gate["automation"]
    if automation == "AUTO" && verification_types.any? { |value| value != "AUTO" }
      violations << "#{file}: AUTO gate cannot contain HYBRID or MANUAL criteria"
    end
    if automation == "HYBRID" && verification_types.all? { |value| value == "AUTO" }
      violations << "#{file}: HYBRID gate needs at least one HYBRID or MANUAL criterion"
    end
  end

  def validate_artifacts(gate, file, allowed)
    artifacts = gate["artifacts"]
    unless artifacts.is_a?(Array) && !artifacts.empty?
      violations << "#{file}: canonical artifacts must be a non-empty list"
      return
    end

    ids = Set.new
    artifacts.each_with_index do |artifact, index|
      label = "#{file}: artifacts[#{index}]"
      unless artifact.is_a?(Hash)
        violations << "#{label} must be an object"
        next
      end
      %w[id type path required_for].each do |field|
        violations << "#{label} missing #{field}" if blank?(artifact[field])
      end
      violations << "#{label} duplicate artifact id #{artifact['id']}" if ids.include?(artifact["id"])
      ids << artifact["id"]
      type = artifact["type"]
      unless Array(allowed["artifact_type"]).include?(type)
        violations << "#{label} invalid type #{type.inspect}"
      end
      path = artifact["path"].to_s
      if type == "repository_input" && !File.file?(absolute(path))
        violations << "#{label} repository input does not exist: #{path}"
      elsif type == "generated_evidence" && !path.start_with?(".quality/")
        violations << "#{label} generated evidence must stay below .quality/"
      elsif type == "manual_evidence" && !path.start_with?("docs/project/")
        violations << "#{label} manual evidence must stay below docs/project/"
      end
      invalid_profiles = Array(artifact["required_for"]) - Array(gate["profile_scope"])
      unless invalid_profiles.empty?
        violations << "#{label} references profiles outside profile_scope: #{invalid_profiles.join(', ')}"
      end
    end
  end

  def validate_decision(gate, file)
    decision = gate["decision"]
    unless decision.is_a?(Hash) && !blank?(decision["pass"]) && !blank?(decision["fail"])
      violations << "#{file}: canonical decision needs pass and fail statements"
    end
    if gate["automation"] == "HYBRID" && blank?(decision&.dig("manual_review"))
      violations << "#{file}: HYBRID decision needs a manual_review boundary"
    end
  end

  def validate_audit(gate, file)
    audit = gate["audit"]
    required = %w[validator tests local_runner ci_workflow evidence_output]
    unless audit.is_a?(Hash)
      violations << "#{file}: canonical audit must be an object"
      return
    end
    required.each do |field|
      value = audit[field]
      violations << "#{file}: audit missing #{field}" if blank?(value)
    end
    %w[validator tests local_runner ci_workflow].each do |field|
      path = audit[field].to_s
      violations << "#{file}: audit #{field} does not exist: #{path}" unless File.file?(absolute(path))
    end
    unless audit["evidence_output"].to_s.start_with?(".quality/")
      violations << "#{file}: audit evidence_output must stay below .quality/"
    end
  end

  def validate_waiver(gate, file)
    waiver = gate["waiver"]
    unless waiver.is_a?(Hash) && [true, false].include?(waiver["allowed"])
      violations << "#{file}: waiver.allowed must be true or false"
      return
    end
    return if waiver["allowed"] == true

    unless Array(waiver["conditions"]).empty? && waiver["maximum_days"].nil?
      violations << "#{file}: prohibited waiver cannot define conditions or maximum_days"
    end
  end

  def validate_links(gate, file)
    links = gate["links"]
    unless links.is_a?(Hash)
      violations << "#{file}: canonical links must be an object"
      return
    end
    validate_link_set(file, links, "requirements", @requirement_ids)
    validate_link_set(file, links, "improvements", @improvement_ids)
    validate_link_set(file, links, "gaps", @gap_ids)
    validate_link_set(file, links, "risks", @risk_ids)
    Array(links["related_adrs"]).each do |value|
      normalized = value.to_s.rjust(4, "0")
      violations << "#{file}: unknown ADR #{normalized}" unless @adr_ids.include?(normalized)
    end
  end

  def validate_link_set(file, links, field, known)
    Array(links[field]).each do |value|
      violations << "#{file}: unknown #{field} reference #{value}" unless known.include?(value)
    end
  end

  def blank?(value, allow_empty: false)
    return true if value.nil?
    return false if allow_empty
    return value.empty? if value.respond_to?(:empty?)

    false
  end

  def build_report
    canonical = @gate_results.count { |gate| gate["schema_profile"] == CANONICAL_PROFILE }
    @report = {
      "schema_version" => "1.0",
      "generated_at" => Time.now.utc.iso8601,
      "decision" => violations.empty? ? "PASS" : "FAIL",
      "counts" => {
        "gates" => @gate_results.length,
        "canonical" => canonical,
        "legacy_compatible" => @gate_results.length - canonical,
        "violations" => violations.length,
        "warnings" => warnings.length,
      },
      "gates" => @gate_results,
      "violations" => violations,
      "warnings" => warnings,
    }
  end

  def write_report
    target = absolute(@report_path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, JSON.pretty_generate(report) + "\n")
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    report_path: ".quality/gate-definitions/report.json",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--report PATH") { |value| options[:report_path] = value }
  end.parse!

  validator = GateDefinitionValidator.new(**options)
  if validator.run
    counts = validator.report["counts"]
    puts "Gate definition quality PASS: #{counts['gates']} gates, #{counts['canonical']} canonical, #{counts['legacy_compatible']} compatible legacy"
    exit 0
  end

  warn "Gate definition quality FAIL:"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
