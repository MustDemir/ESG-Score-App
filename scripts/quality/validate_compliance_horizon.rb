#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "optparse"
require "set"
require "time"
require "yaml"

class ComplianceHorizonValidator
  VALID_PROFILES = %w[development release_candidate submission].freeze
  VALID_GATES = %w[horizon regulatory_applicability uwg_comparison_transparency].freeze
  VALID_TRIGGER_KINDS = %w[release_profile any_flag_true all_flags_true].freeze
  VALID_STATES = %w[applicable not_applicable].freeze
  VALID_RELEASE_EVIDENCE = %w[approved governed_by_linked_gate not_due not_applicable].freeze

  attr_reader :repo_root, :violations, :warnings, :report

  def initialize(repo_root:, profile: "development", gate: "horizon", report_path: ".quality/compliance-horizon/report.json", source_observation_report_path: nil, today: Date.today)
    @repo_root = File.expand_path(repo_root)
    @profile = profile
    @gate = gate
    @report_path = report_path
    @source_observation_report_path = source_observation_report_path
    @today = today
    @violations = []
    @warnings = []
  end

  def run
    validate_options
    load_documents
    validate_horizon
    validate_regulatory_applicability if @gate == "regulatory_applicability"
    validate_uwg_comparison_transparency if @gate == "uwg_comparison_transparency"
    build_report
    write_report
    violations.empty?
  end

  private

  def absolute(relative)
    File.join(@repo_root, relative)
  end

  def load_yaml(relative)
    YAML.safe_load(File.read(absolute(relative), encoding: "UTF-8"), permitted_classes: [Date, Time], aliases: true) || {}
  rescue Errno::ENOENT
    violations << "#{relative}: file is missing"
    {}
  rescue Psych::SyntaxError => error
    violations << "#{relative}: invalid YAML: #{error.message.lines.first.strip}"
    {}
  end

  def load_json(relative)
    JSON.parse(File.read(absolute(relative), encoding: "UTF-8"))
  rescue Errno::ENOENT
    violations << "#{relative}: file is missing"
    {}
  rescue JSON::ParserError => error
    violations << "#{relative}: invalid JSON: #{error.message}"
    {}
  end

  def validate_options
    violations << "invalid profile #{@profile.inspect}" unless VALID_PROFILES.include?(@profile)
    violations << "invalid gate #{@gate.inspect}" unless VALID_GATES.include?(@gate)
  end

  def load_documents
    @horizon = load_yaml("docs/project/compliance/regulatory-horizon.yaml")
    @sources = Array(load_yaml("docs/project/compliance/source-register.yaml")["sources"])
    @source_ids = @sources.map { |source| source["id"] }.to_set
    @source_baseline = load_yaml("docs/project/compliance/source-observation-baseline.yaml")
    @source_review_log = load_yaml("docs/project/compliance/source-observation-review-log.yaml")
    @manifest = load_json("docs/project/compliance/compliance-manifest.json")
    @controls = Array(@horizon["controls"])
  end

  def validate_horizon
    %w[schema_version last_reviewed next_full_review_due owner scope review_policy capability_inventory controls].each do |field|
      violation("regulatory-horizon.yaml: missing #{field}") if blank?(@horizon[field])
    end
    violation("regulatory-horizon.yaml: schema_version must be 1.0") unless @horizon["schema_version"] == "1.0"
    validate_date(@horizon["last_reviewed"], "regulatory-horizon.yaml: last_reviewed")
    validate_date(@horizon["next_full_review_due"], "regulatory-horizon.yaml: next_full_review_due")
    enforce_review_deadline(@horizon["next_full_review_due"], "regulatory-horizon.yaml: full review")

    review_policy = @horizon["review_policy"] || {}
    violation("regulatory-horizon.yaml: official sources must be required") unless review_policy["official_sources_only"] == true
    violation("regulatory-horizon.yaml: automatic approval must be prohibited") unless review_policy["automatic_approval"] == "prohibited"

    inventory = @horizon["capability_inventory"] || {}
    violation("regulatory-horizon.yaml: capability inventory path must identify the manifest") unless inventory["path"] == "docs/project/compliance/compliance-manifest.json"
    violation("regulatory-horizon.yaml: capability inventory must identify its declaration contract") unless inventory["contract_path"] == "docs/project/compliance/capability-declaration-contract.yaml"
    violation("regulatory-horizon.yaml: capability declaration contract is missing") unless File.file?(absolute(inventory["contract_path"].to_s))
    violation("regulatory-horizon.yaml: capability inventory assertion is missing") if blank?(inventory["assertion"])
    violation("regulatory-horizon.yaml: controls must not be empty") if @controls.empty?
    validate_source_observation_baseline
    validate_source_observation_review_log
    validate_source_observation_report if @source_observation_report_path

    ids = Set.new
    @controls.each { |control| validate_control(control, ids) }
  end

  def validate_source_observation_baseline
    %w[schema_version captured_at owner purpose automatic_approval sources].each do |field|
      violation("source-observation-baseline.yaml: missing #{field}") if blank?(@source_baseline[field])
    end
    violation("source-observation-baseline.yaml: schema_version must be 1.0") unless @source_baseline["schema_version"] == "1.0"
    violation("source-observation-baseline.yaml: automatic approval must be prohibited") unless @source_baseline["automatic_approval"] == "prohibited"
    timestamp = Time.parse(@source_baseline["captured_at"].to_s)
    violation("source-observation-baseline.yaml: captured_at must be an ISO timestamp") unless timestamp.utc.iso8601 == @source_baseline["captured_at"]
    baseline_sources = Array(@source_baseline["sources"])
    baseline_ids = baseline_sources.map { |source| source["id"] }
    violation("source-observation-baseline.yaml: source IDs must exactly match horizon sources") unless baseline_ids.to_set == horizon_source_ids && baseline_ids.length == horizon_source_ids.length
    baseline_sources.each do |source|
      id = source["id"] || "<unknown source>"
      violation("source-observation-baseline.yaml: #{id} has invalid state signature") unless source["state_signature"].to_s.match?(/\A[0-9a-f]{64}\z/)
      violation("source-observation-baseline.yaml: #{id} has no content marker status") if blank?(source["content_marker_status"])
    end
  rescue ArgumentError
    violation("source-observation-baseline.yaml: captured_at must be an ISO timestamp")
  end

  def validate_source_observation_review_log
    %w[schema_version owner purpose automatic_approval entries].each do |field|
      violation("source-observation-review-log.yaml: missing #{field}") unless @source_review_log.key?(field)
    end
    violation("source-observation-review-log.yaml: schema_version must be 1.0") unless @source_review_log["schema_version"] == "1.0"
    violation("source-observation-review-log.yaml: automatic approval must be prohibited") unless @source_review_log["automatic_approval"] == "prohibited"

    @source_review_entries = Array(@source_review_log["entries"])
    @source_review_entries.each do |entry|
      source_id = entry["source_id"] || "<unknown source>"
      %w[source_id observed_state_signature observation_generated_at assessment reviewed_at reviewer_role evidence automatic_approval].each do |field|
        violation("source-observation-review-log.yaml: #{source_id} missing #{field}") if blank?(entry[field])
      end
      violation("source-observation-review-log.yaml: unknown source #{source_id}") unless horizon_source_ids.include?(source_id)
      violation("source-observation-review-log.yaml: #{source_id} has invalid observed state signature") unless entry["observed_state_signature"].to_s.match?(/\A[0-9a-f]{64}\z/)
      validate_iso_timestamp(entry["observation_generated_at"], "source-observation-review-log.yaml: #{source_id} observation_generated_at")
      validate_iso_timestamp(entry["reviewed_at"], "source-observation-review-log.yaml: #{source_id} reviewed_at")
      violation("source-observation-review-log.yaml: #{source_id} assessment must be completed") unless entry["assessment"] == "completed"
      violation("source-observation-review-log.yaml: #{source_id} must not permit automatic approval") unless entry["automatic_approval"] == false
      evidence = entry["evidence"].to_s
      violation("source-observation-review-log.yaml: #{source_id} review evidence is missing") unless File.file?(absolute(evidence))
    end
  end

  def validate_source_observation_report
    path = absolute(@source_observation_report_path)
    unless File.file?(path)
      return violation("source observation report is missing: #{@source_observation_report_path}")
    end

    source_report = JSON.parse(File.read(path, encoding: "UTF-8"))
    violation("source observation report must prohibit automatic approval") unless source_report["automatic_approval"] == false
    validate_iso_timestamp(source_report["generated_at"], "source observation report generated_at")
    Array(source_report["sources"]).each do |source|
      source_id = source["id"] || "<unknown source>"
      violation("source observation report references unknown source #{source_id}") unless horizon_source_ids.include?(source_id)
      next unless source["manual_review_required"] == true

      signature = source["state_signature"].to_s
      matching_review = @source_review_entries.find do |entry|
        entry["source_id"] == source_id && entry["observed_state_signature"] == signature
      end
      if matching_review.nil?
        enforce_profiled_finding("#{source_id}: source observation #{source['change_signal']} lacks a matching manual review record")
        next
      end

      reviewed_at = parse_timestamp(matching_review["reviewed_at"])
      observed_at = parse_timestamp(matching_review["observation_generated_at"])
      if reviewed_at.nil? || observed_at.nil? || reviewed_at < observed_at
        enforce_profiled_finding("#{source_id}: manual review predates the observed source state")
      end
    end
  rescue JSON::ParserError => error
    violation("source observation report is invalid JSON: #{error.message}")
  end

  def horizon_source_ids
    @controls.flat_map { |control| Array(control["source_refs"]) }.to_set
  end

  def validate_control(control, ids)
    label = "#{control['id'] || '<unknown control>'}"
    %w[id title source_refs obligation effective_date applicability owner implementation_status linked_gates release_evidence_status manual_change_assessment next_review_due].each do |field|
      violation("#{label}: missing #{field}") if blank?(control[field])
    end
    violation("#{label}: duplicate control id") if ids.include?(control["id"])
    ids << control["id"]
    violation("#{label}: id must use HZN- prefix") unless control["id"].to_s.match?(/\AHZN-[A-Z0-9-]+\z/)
    violation("#{label}: obligation must be MUST or SHOULD") unless %w[MUST SHOULD].include?(control["obligation"])
    validate_date(control["effective_date"], "#{label}: effective_date")
    validate_date(control["next_review_due"], "#{label}: next_review_due")
    enforce_review_deadline(control["next_review_due"], "#{label}: control review")
    Array(control["source_refs"]).each { |source| violation("#{label}: unknown source #{source}") unless @source_ids.include?(source) }
    validate_applicability(control, label)
    validate_manual_assessment(control, label)
    validate_release_evidence(control, label)

    if control["id"] == "HZN-EU-GREEN-TRANSITION"
      validate_comparison_contract(control, label)
    end
  end

  def validate_applicability(control, label)
    applicability = control["applicability"] || {}
    kind = applicability["kind"]
    violation("#{label}: invalid applicability kind") unless VALID_TRIGGER_KINDS.include?(kind)
    violation("#{label}: invalid current_state") unless VALID_STATES.include?(applicability["current_state"])
    flags = Array(applicability["flags"])
    if %w[any_flag_true all_flags_true].include?(kind)
      violation("#{label}: capability trigger needs at least one flag") if flags.empty?
      flags.each { |flag| violation("#{label}: manifest flag #{flag} is missing") unless @manifest.key?(flag) && [true, false].include?(@manifest[flag]) }
    end
    if applicability["current_state"] == "not_applicable"
      %w[rationale reactivation_trigger].each { |field| violation("#{label}: inactive control needs #{field}") if blank?(applicability[field]) }
    elsif blank?(applicability["reactivation_trigger"])
      violation("#{label}: applicable control needs a reactivation_trigger")
    end

    expected_state = triggered?(applicability) ? "applicable" : "not_applicable"
    unless kind == "release_profile" && @profile == "development"
      violation("#{label}: current_state must be #{expected_state} for its manifest trigger") unless applicability["current_state"] == expected_state
    end
  end

  def triggered?(applicability)
    case applicability["kind"]
    when "release_profile" then @profile != "development"
    when "any_flag_true" then Array(applicability["flags"]).any? { |flag| @manifest[flag] == true }
    when "all_flags_true" then Array(applicability["flags"]).all? { |flag| @manifest[flag] == true }
    else false
    end
  end

  def validate_manual_assessment(control, label)
    assessment = control["manual_change_assessment"] || {}
    %w[status reviewed_at reviewer_role evidence automatic_approval].each do |field|
      violation("#{label}: manual_change_assessment missing #{field}") if blank?(assessment[field])
    end
    violation("#{label}: manual_change_assessment must be reviewed") unless assessment["status"] == "reviewed"
    violation("#{label}: manual_change_assessment must prohibit automatic approval") unless assessment["automatic_approval"] == false
    validate_date(assessment["reviewed_at"], "#{label}: manual_change_assessment.reviewed_at")
    evidence = assessment["evidence"].to_s
    violation("#{label}: manual assessment evidence is missing") unless File.file?(absolute(evidence))
  end

  def validate_release_evidence(control, label)
    status = control["release_evidence_status"]
    violation("#{label}: invalid release_evidence_status") unless VALID_RELEASE_EVIDENCE.include?(status)
    return unless release_profile? && control["obligation"] == "MUST" && triggered?(control["applicability"] || {})

    effective_date = parse_date(control["effective_date"])
    return if effective_date.nil? || effective_date > @today
    return if %w[approved governed_by_linked_gate].include?(status)

    violation("#{label}: due applicable MUST has no release evidence")
  end

  def validate_regulatory_applicability
    @controls.each do |control|
      applicability = control["applicability"] || {}
      next unless applicability["current_state"] == "not_applicable"

      violation("#{control['id']}: inactive control lacks an owner") if blank?(control["owner"])
      violation("#{control['id']}: inactive control lacks a next review date") if blank?(control["next_review_due"])
      violation("#{control['id']}: inactive control cannot claim approved release evidence") if control["release_evidence_status"] == "approved"
    end
  end

  def validate_uwg_comparison_transparency
    control = @controls.find { |item| item["id"] == "HZN-EU-GREEN-TRANSITION" }
    return violation("HZN-EU-GREEN-TRANSITION: control is missing") if control.nil?

    validate_comparison_contract(control, "HZN-EU-GREEN-TRANSITION")
    return unless release_profile? && triggered?(control["applicability"] || {})

    effective_date = parse_date(control["effective_date"])
    return if effective_date.nil? || effective_date > @today
    contract = control["comparison_contract"] || {}
    violation("HZN-EU-GREEN-TRANSITION: qualified legal review is required after the effective date") unless contract["legal_review_status"] == "approved"
  end

  def validate_comparison_contract(control, label)
    contract = control["comparison_contract"] || {}
    %w[methodology_path comparison_scope comparison_population source_freshness_contract legal_review_status legal_review_due].each do |field|
      violation("#{label}: comparison_contract missing #{field}") if blank?(contract[field])
    end
    %w[methodology_path source_freshness_contract].each do |field|
      path = contract[field].to_s
      violation("#{label}: #{field} does not exist") unless File.file?(absolute(path))
    end
    validate_date(contract["legal_review_due"], "#{label}: legal_review_due")
    legal_review_due = parse_date(contract["legal_review_due"])
    return if legal_review_due.nil? || @today <= legal_review_due
    return if contract["legal_review_status"] == "approved"

    enforce_profiled_finding(
      "#{label}: qualified legal review overdue since #{legal_review_due}",
    )
  end

  def enforce_review_deadline(value, label)
    due_date = parse_date(value)
    return if due_date.nil? || @today <= due_date

    enforce_profiled_finding("#{label} overdue since #{due_date}")
  end

  def enforce_profiled_finding(message)
    release_profile? ? violation(message) : warnings << message
  end

  def release_profile?
    %w[release_candidate submission].include?(@profile)
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def parse_timestamp(value)
    Time.parse(value.to_s).utc
  rescue ArgumentError
    nil
  end

  def validate_iso_timestamp(value, label)
    timestamp = parse_timestamp(value)
    violation("#{label} must be an ISO timestamp") if timestamp.nil? || timestamp.iso8601 != value
  end

  def validate_date(value, label)
    violation("#{label} must be an ISO date") if parse_date(value).nil?
  end

  def blank?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  def violation(message)
    violations << message
  end

  def build_report
    @report = {
      "schema_version" => "1.0",
      "generated_at" => Time.now.utc.iso8601,
      "profile" => @profile,
      "gate" => @gate,
      "decision" => violations.empty? ? "PASS" : "FAIL",
      "controls" => @controls.map do |control|
        {
          "id" => control["id"],
          "applicability" => control.dig("applicability", "current_state"),
          "effective_date" => control["effective_date"],
          "release_evidence_status" => control["release_evidence_status"],
        }
      end,
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
    profile: ENV.fetch("COMPLIANCE_PROFILE", "development"),
    gate: "horizon",
    report_path: ".quality/compliance-horizon/report.json",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--profile PROFILE") { |value| options[:profile] = value }
    parser.on("--gate GATE") { |value| options[:gate] = value }
    parser.on("--report PATH") { |value| options[:report_path] = value }
    parser.on("--source-observation-report PATH") { |value| options[:source_observation_report_path] = value }
  end.parse!

  validator = ComplianceHorizonValidator.new(**options)
  if validator.run
    puts "Compliance horizon #{options[:gate]} PASS: #{validator.report['controls'].length} controls, profile #{options[:profile]}"
    exit 0
  end

  warn "Compliance horizon #{options[:gate]} FAIL:"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
