#!/usr/bin/env ruby

require "cgi"
require "date"
require "digest"
require "fileutils"
require "json"
require "net/http"
require "optparse"
require "time"
require "uri"
require "yaml"

class ProviderGovernanceValidator
  GATES = {
    "dpa" => ["G-PROVIDER-DPA", "dpa"],
    "subprocessors" => ["G-PROVIDER-SUBPROCESSORS", "subprocessors"],
    "cost" => ["G-COST-CONTROL", "cost_control"],
  }.freeze
  PROFILES = %w[development remote_backend release_candidate].freeze

  attr_reader :violations, :warnings, :report

  def initialize(
    repo_root:,
    gate:,
    profile: "development",
    online_sources: false,
    report_dir: ".quality/provider-governance",
    today: Date.today
  )
    @repo_root = File.expand_path(repo_root)
    @gate = gate
    @profile = profile
    @online_sources = online_sources
    @report_dir = report_dir
    @today = today
    @violations = []
    @warnings = []
    @online_status = "not_requested"
  end

  def run
    load_inputs
    validate_shared
    case @gate
    when "dpa" then validate_dpa
    when "subprocessors" then validate_subprocessors
    when "cost" then validate_cost
    else violations << "unknown provider governance gate #{@gate.inspect}"
    end
    validate_strict_profile if %w[remote_backend release_candidate].include?(@profile)
    validate_online_source if @online_sources && GATES.key?(@gate)
    build_report
    write_report
    violations.empty?
  end

  private

  def path(relative)
    File.join(@repo_root, relative)
  end

  def load_yaml(relative)
    YAML.safe_load(
      File.read(path(relative), encoding: "UTF-8"),
      permitted_classes: [Date, Time],
      aliases: true,
    ) || {}
  rescue Errno::ENOENT
    violations << "#{relative}: file is missing"
    {}
  rescue Psych::SyntaxError => error
    violations << "#{relative}: invalid YAML: #{error.message.lines.first.strip}"
    {}
  end

  def load_inputs
    @register = load_yaml("docs/project/compliance/provider-governance-register.yaml")
    @environment = load_yaml("docs/project/security/eu-supabase-environment-contract.yaml")
    source_register = load_yaml("docs/project/compliance/source-register.yaml")
    @sources = Array(source_register["sources"]).to_h { |source| [source["id"], source] }
    review_key = GATES.dig(@gate, 1)
    @review = @register.dig("reviews", review_key) || {}
  end

  def validate_shared
    required = %w[
      schema_version last_reviewed owner environment provider project_name
      region region_display_name region_verification data_classification
      personal_data_allowed remote_schema_deployed remote_app_access_enabled
      reviews activation_policy
    ]
    require_fields(@register, required, "provider-governance-register")
    unless @register["schema_version"] == "1.0" &&
           @register["environment"] == "development" &&
           @register["provider"] == "Supabase"
      violations << "provider register must describe the Supabase development environment"
    end
    unless @register["project_name"] == "scanfair-dev" &&
           @register["region"] == "eu-central-1" &&
           @register.dig("region_verification", "status") == "verified"
      violations << "development project name and eu-central-1 region must be verified"
    end
    unless @register["personal_data_allowed"] == false
      violations << "development provider register must prohibit personal data"
    end
    validate_date(@register["last_reviewed"], "provider register last_reviewed", future_allowed: false)

    if @profile == "development"
      unless @environment["remote_backend_enabled"] == false &&
             @register["remote_schema_deployed"] == true &&
             @register["remote_app_access_enabled"] == false
        violations << "development profile must record the deployed schema with runtime app access disabled"
      end
    end

    require_fields(
      @review,
      %w[source_id expected_version last_verified_at next_periodic_review_at change_check_interval_days decision reviewer_role decision_reason online_markers],
      "#{@gate} review",
    )
    validate_review_dates
    validate_source_binding
  end

  def validate_review_dates
    last = validate_date(@review["last_verified_at"], "#{@gate} last_verified_at", future_allowed: false)
    next_review = validate_date(@review["next_periodic_review_at"], "#{@gate} next_periodic_review_at", future_allowed: true)
    if last && next_review && next_review <= last
      violations << "#{@gate}: next periodic review must be after the last verification"
    end
    if next_review && next_review < @today
      violations << "#{@gate}: periodic review is overdue since #{next_review}"
    end
    interval = @review["change_check_interval_days"]
    unless interval.is_a?(Integer) && interval.between?(1, 31)
      violations << "#{@gate}: change_check_interval_days must be between 1 and 31"
    end
  end

  def validate_source_binding
    source = @sources[@review["source_id"]]
    if source.nil?
      violations << "#{@gate}: unknown source #{@review['source_id'].inspect}"
      return
    end
    unless source["version"].to_s == @review["expected_version"].to_s
      violations << "#{@gate}: source-register version does not match expected_version"
    end
    uri = URI.parse(source["url"].to_s)
    violations << "#{@gate}: source URL must use HTTPS" unless uri.is_a?(URI::HTTPS)
    markers = Array(@review["online_markers"])
    violations << "#{@gate}: online source markers must not be empty" if markers.empty?
  rescue URI::InvalidURIError
    violations << "#{@gate}: source URL is invalid"
  end

  def validate_dpa
    require_fields(
      @review,
      %w[effective_date contract_mechanism processing_scope],
      "dpa review",
    )
    effective = validate_date(@review["effective_date"], "dpa effective_date", future_allowed: false)
    violations << "dpa: effective date cannot be in the future" if effective && effective > @today
    unless @review["contract_mechanism"] == "incorporated_into_supabase_terms"
      violations << "dpa: contract mechanism must match the reviewed provider terms"
    end
    unless @review["processing_scope"] == "non_personal_development_only"
      violations << "dpa: development processing scope must remain non-personal"
    end
    allowed = Array(@register.dig("activation_policy", "development", "dpa_decisions_allowed"))
    unless allowed.include?(@review["decision"])
      violations << "dpa: development decision #{@review['decision'].inspect} is not allowed"
    end
  end

  def validate_subprocessors
    require_fields(@review, %w[change_notification_subscription], "subprocessor review")
    unless %w[pending_owner_action confirmed].include?(@review["change_notification_subscription"])
      violations << "subprocessors: invalid change-notification status"
    end
    allowed = Array(@register.dig("activation_policy", "development", "subprocessor_decisions_allowed"))
    unless allowed.include?(@review["decision"])
      violations << "subprocessors: development decision #{@review['decision'].inspect} is not allowed"
    end
  end

  def validate_cost
    require_fields(
      @review,
      %w[plan plan_verification expected_fixed_monthly_cost_usd paid_add_ons_allowed spend_cap thresholds_percent usage_review_interval_days],
      "cost review",
    )
    unless @review["plan"] == "free" &&
           @review["expected_fixed_monthly_cost_usd"] == 0 &&
           @review["paid_add_ons_allowed"] == false &&
           @review["spend_cap"] == "unavailable_on_free_plan"
      violations << "cost: Free Plan, zero fixed cost, no paid add-ons and unavailable Spend Cap must be represented consistently"
    end
    expected = %w[database_size egress edge_function_invocations]
    thresholds = @review["thresholds_percent"] || {}
    expected.each do |metric|
      value = thresholds[metric]
      unless value.is_a?(Integer) && value.between?(1, 70)
        violations << "cost: #{metric} threshold must be between 1 and 70 percent"
      end
    end
    interval = @review["usage_review_interval_days"]
    unless interval.is_a?(Integer) && interval.between?(1, 7)
      violations << "cost: usage review interval must be between 1 and 7 days"
    end
    allowed = Array(@register.dig("activation_policy", "development", "cost_decisions_allowed"))
    unless allowed.include?(@review["decision"])
      violations << "cost: development decision #{@review['decision'].inspect} is not allowed"
    end
  end

  def validate_strict_profile
    unless @environment["remote_backend_enabled"] == true &&
           @environment["implementation_state"] == "deployed_to_eu_development" &&
           @register["remote_schema_deployed"] == true &&
           @register["remote_app_access_enabled"] == true
      violations << "#{@profile}: remote backend must be deployed and explicitly enabled"
    end
    case @gate
    when "dpa"
      required = @register.dig("activation_policy", "remote_backend", "required_dpa_decision")
      violations << "remote_backend: DPA owner approval is required" unless @review["decision"] == required
    when "subprocessors"
      required_decision = @register.dig("activation_policy", "remote_backend", "required_subprocessor_decision")
      required_subscription = @register.dig("activation_policy", "remote_backend", "required_change_notification_subscription")
      unless @review["decision"] == required_decision && @review["change_notification_subscription"] == required_subscription
        violations << "remote_backend: subprocessor approval and confirmed change notifications are required"
      end
    when "cost"
      required = @register.dig("activation_policy", "remote_backend", "required_plan_verification")
      violations << "remote_backend: reviewed dashboard plan evidence is required" unless @review["plan_verification"] == required
    end
    validate_provider_approval_evidence
  end

  def validate_provider_approval_evidence
    contract = @register["provider_approval_evidence"] || {}
    relative_path = contract["path"].to_s
    absolute_path = safe_evidence_path(relative_path, "provider approval")
    return unless absolute_path
    unless File.file?(absolute_path)
      violations << "#{@profile}: typed provider approval evidence is missing: #{relative_path}"
      return
    end

    evidence = YAML.safe_load(
      File.read(absolute_path, encoding: "UTF-8"),
      permitted_classes: [Date, Time],
      aliases: true,
    ) || {}
    unless evidence["evidence_type"] == contract["evidence_type"]
      violations << "#{@profile}: provider approval evidence_type is invalid"
    end
    contract.fetch("required_values", {}).each do |field, expected|
      unless evidence[field] == expected
        violations << "#{@profile}: provider approval #{field} must be #{expected.inspect}"
      end
    end
    require_fields(evidence, Array(contract["required_fields"]), "provider approval evidence")

    unless evidence["reviewed_commit_sha"].to_s.match?(/\A[0-9a-f]{40}\z/)
      violations << "#{@profile}: provider approval reviewed_commit_sha must be a full lowercase Git SHA"
    end
    required_roles = Array(contract["required_reviewer_roles"])
    missing_roles = required_roles - Array(evidence["reviewer_roles"])
    unless missing_roles.empty?
      violations << "#{@profile}: provider approval is missing reviewer roles: #{missing_roles.join(', ')}"
    end
    qualifications = evidence["reviewer_qualifications"]
    unless qualifications.is_a?(Hash) && required_roles.all? { |role| !qualifications[role].to_s.strip.empty? }
      violations << "#{@profile}: provider approval needs a qualification statement for every reviewer role"
    end
    unless Array(evidence["approved_profiles"]).include?(@profile)
      violations << "#{@profile}: provider approval does not cover this profile"
    end
    gate_id = GATES.dig(@gate, 0)
    unless Array(evidence["approved_gates"]).include?(gate_id)
      violations << "#{@profile}: provider approval does not cover #{gate_id}"
    end

    expected_sources = Array(contract["required_source_ids"])
    source_versions = evidence["source_versions"] || {}
    expected_sources.each do |source_id|
      source = @sources[source_id] || {}
      unless source_versions[source_id].to_s == source["version"].to_s
        violations << "#{@profile}: provider approval source version for #{source_id} is missing or stale"
      end
    end

    validate_evidence_freshness(evidence["reviewed_at"], contract)
    validate_evidence_digest(evidence, "provider_register_sha256", "docs/project/compliance/provider-governance-register.yaml")
    validate_evidence_digest(evidence, "artifact_sha256", evidence["artifact_path"])
  rescue Psych::SyntaxError => error
    violations << "#{@profile}: invalid provider approval evidence YAML: #{error.message.lines.first.strip}"
  end

  def validate_evidence_freshness(value, contract)
    reviewed_at = Time.iso8601(value.to_s)
    reviewed_date = reviewed_at.to_date
    if reviewed_date > @today
      violations << "#{@profile}: provider approval reviewed_at cannot be in the future"
      return
    end
    maximum_age = if @profile == "release_candidate"
                    @register.dig("activation_policy", "release_candidate", "maximum_evidence_age_days")
                  else
                    contract["maximum_remote_age_days"]
                  end
    unless maximum_age.is_a?(Integer) && maximum_age.positive?
      violations << "#{@profile}: provider approval maximum evidence age is invalid"
      return
    end
    if reviewed_date < @today - maximum_age
      violations << "#{@profile}: provider approval evidence is older than #{maximum_age} days"
    end
  rescue ArgumentError
    violations << "#{@profile}: provider approval reviewed_at must be an ISO timestamp"
  end

  def validate_evidence_digest(evidence, digest_field, target_relative)
    expected = evidence[digest_field].to_s
    unless expected.match?(/\A[0-9a-f]{64}\z/)
      violations << "#{@profile}: #{digest_field} must be a lowercase SHA-256"
      return
    end
    target = safe_evidence_path(target_relative, digest_field, allow_register: true)
    return unless target
    unless File.file?(target)
      violations << "#{@profile}: digest target is missing: #{target_relative}"
      return
    end
    actual = Digest::SHA256.file(target).hexdigest
    violations << "#{@profile}: #{digest_field} does not match #{target_relative}" unless expected == actual
  end

  def safe_evidence_path(relative_path, label, allow_register: false)
    allowed = relative_path.to_s.start_with?("docs/project/compliance/evidence/")
    allowed ||= allow_register && relative_path == "docs/project/compliance/provider-governance-register.yaml"
    unless allowed
      violations << "#{@profile}: #{label} path must stay in the provider compliance evidence boundary"
      return nil
    end
    absolute = File.expand_path(relative_path.to_s, @repo_root)
    unless absolute.start_with?("#{@repo_root}#{File::SEPARATOR}")
      violations << "#{@profile}: #{label} path leaves the repository"
      return nil
    end
    absolute
  end

  def validate_online_source
    source = @sources[@review["source_id"]]
    return unless source

    text = fetch_text(source["url"])
    return unless text

    missing = Array(@review["online_markers"]).reject { |marker| text.include?(marker) }
    if missing.empty?
      @online_status = "matched_expected_markers"
    else
      @online_status = "review_required"
      violations << "#{@gate}: official source changed or expected markers are missing"
    end
  end

  def fetch_text(url, redirects: 5)
    raise "too many redirects" if redirects.negative?

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTPS)
      violations << "#{@gate}: official source and redirects must remain HTTPS"
      @online_status = "unavailable"
      return nil
    end
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "ScanFair-Provider-Governance/1.0"
    request["Accept-Encoding"] = "identity"
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 8,
      read_timeout: 12,
    ) { |http| http.request(request) }

    if response.is_a?(Net::HTTPRedirection)
      location = URI.join(uri, response["location"]).to_s
      return fetch_text(location, redirects: redirects - 1)
    end
    unless response.is_a?(Net::HTTPSuccess)
      violations << "#{@gate}: official source returned HTTP #{response.code}"
      @online_status = "unavailable"
      return nil
    end
    if response.body.bytesize > 3_000_000
      violations << "#{@gate}: official source response exceeds 3 MB"
      @online_status = "unavailable"
      return nil
    end

    CGI.unescapeHTML(response.body.gsub(/<[^>]+>/, " ").gsub(/\\u0026/, "&").gsub(/\s+/, " "))
  rescue StandardError => error
    violations << "#{@gate}: official source check failed (#{error.class})"
    @online_status = "unavailable"
    nil
  end

  def validate_date(value, label, future_allowed:)
    date = value.is_a?(Date) ? value : Date.iso8601(value.to_s)
    if !future_allowed && date > @today
      violations << "#{label} cannot be in the future"
    end
    date
  rescue ArgumentError
    violations << "#{label} must be an ISO date"
    nil
  end

  def require_fields(object, fields, label)
    fields.each do |field|
      value = object[field]
      if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        violations << "#{label}: missing #{field}"
      end
    end
  end

  def build_report
    gate_id = GATES.dig(@gate, 0) || @gate
    @report = {
      "schema_version" => "1.0",
      "generated_at" => Time.now.utc.iso8601,
      "gate_id" => gate_id,
      "profile" => @profile,
      "decision" => violations.empty? ? "PASS" : "FAIL",
      "governance_decision" => @review["decision"],
      "remote_backend_enabled" => @environment["remote_backend_enabled"],
      "online_source_check" => @online_status,
      "source_id" => @review["source_id"],
      "expected_version" => @review["expected_version"].to_s,
      "last_verified_at" => @review["last_verified_at"].to_s,
      "next_periodic_review_at" => @review["next_periodic_review_at"].to_s,
      "violations" => violations,
      "warnings" => warnings,
    }
  end

  def write_report
    gate_id = GATES.dig(@gate, 0) || "UNKNOWN"
    target = path(File.join(@report_dir, "#{gate_id}.json"))
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, JSON.pretty_generate(report) + "\n")
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    gate: "dpa",
    profile: "development",
    online_sources: false,
    report_dir: ".quality/provider-governance",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--gate GATE", ProviderGovernanceValidator::GATES.keys) { |value| options[:gate] = value }
    parser.on("--profile PROFILE", ProviderGovernanceValidator::PROFILES) { |value| options[:profile] = value }
    parser.on("--online-sources") { options[:online_sources] = true }
    parser.on("--report-dir PATH") { |value| options[:report_dir] = value }
  end.parse!

  validator = ProviderGovernanceValidator.new(**options)
  if validator.run
    puts "#{validator.report['gate_id']} PASS (#{options[:profile]}): governance decision #{validator.report['governance_decision']}"
    exit 0
  end

  warn "#{validator.report['gate_id']} FAIL (#{options[:profile]}):"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
