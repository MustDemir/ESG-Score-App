#!/usr/bin/env ruby

require "date"
require "digest"
require "json"
require "optparse"
require "set"
require "yaml"

class ClaimsPrivacyBoundaryValidator
  PROFILES = %w[development external_beta remote_backend release_candidate].freeze
  GATES = %w[claims privacy all].freeze
  SHA256_PATTERN = /\A[0-9a-f]{64}\z/.freeze
  UNRESOLVED_PROCESSING_MARKERS = %w[
    missing
    pending
    prohibited_until
    release_blocker
    requires_confirmation
    requires_provider_confirmation
    requires_review
    unknown
  ].freeze

  attr_reader :violations

  def initialize(repo_root:, profile:, gate: "all")
    @repo_root = File.expand_path(repo_root)
    @profile = profile
    @gate = gate
    @violations = []
    @source_ids = load_source_ids
  end

  def run
    validate_claims if %w[claims all].include?(@gate)
    validate_privacy if %w[privacy all].include?(@gate)
    violations.empty?
  end

  private

  def path(relative)
    File.join(@repo_root, relative)
  end

  def read(relative)
    absolute = path(relative)
    return File.read(absolute, encoding: "UTF-8") if File.file?(absolute)

    violations << "#{relative}: file is missing"
    ""
  end

  def load_yaml(relative)
    content = read(relative)
    return {} if content.empty?

    YAML.safe_load(content, permitted_classes: [Date], aliases: true) || {}
  rescue Psych::SyntaxError => error
    violations << "#{relative}: invalid YAML: #{error.message.lines.first.strip}"
    {}
  end

  def load_evidence(relative, label)
    absolute = safe_repo_path(relative, label)
    return {} unless absolute
    unless File.file?(absolute)
      violations << "#{label}: evidence file is missing: #{relative}"
      return {}
    end

    if File.extname(absolute) == ".json"
      JSON.parse(File.read(absolute, encoding: "UTF-8"))
    else
      YAML.safe_load(
        File.read(absolute, encoding: "UTF-8"),
        permitted_classes: [Date],
        aliases: true,
      ) || {}
    end
  rescue JSON::ParserError, Psych::SyntaxError => error
    violations << "#{label}: invalid evidence document: #{error.message}"
    {}
  end

  def safe_repo_path(relative, label)
    if relative.to_s.strip.empty?
      violations << "#{label}: evidence path is missing"
      return nil
    end

    absolute = File.expand_path(relative.to_s, @repo_root)
    root_prefix = "#{@repo_root}#{File::SEPARATOR}"
    unless absolute.start_with?(root_prefix)
      violations << "#{label}: evidence path leaves repository: #{relative}"
      return nil
    end
    absolute
  end

  def load_source_ids
    register = load_yaml("docs/project/compliance/source-register.yaml")
    Array(register["sources"]).map { |source| source["id"] }.compact.to_set
  end

  def require_fields(object, fields, label)
    fields.each do |field|
      value = object[field]
      if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        violations << "#{label}: missing #{field}"
      end
    end
  end

  def require_source_ids(ids, label)
    Array(ids).each do |id|
      violations << "#{label}: unknown source #{id}" unless @source_ids.include?(id)
    end
  end

  def duplicate_ids(records)
    counts = records.each_with_object(Hash.new(0)) do |record, result|
      id = record["id"]
      result[id] += 1 if id
    end
    counts.select { |_id, count| count > 1 }.keys
  end

  def validate_claims
    relative = "docs/project/compliance/claim-inventory.yaml"
    inventory = load_yaml(relative)
    require_fields(
      inventory,
      %w[schema_version last_reviewed owner status public_activation enforcement_profiles reviews evidence_contracts scope_contract health_boundary claims primary_sources],
      relative,
    )
    return if inventory.empty?

    require_source_ids(inventory["primary_sources"], relative)
    validate_claim_scope(inventory, relative)
    validate_health_boundary(inventory, relative)
    validate_claim_records(inventory, relative)
    validate_claim_runtime(inventory)
    validate_claim_profile(inventory, relative)
  end

  def validate_claim_scope(inventory, label)
    scope = inventory.fetch("scope_contract", {})
    required_surfaces = %w[app_runtime app_store website_marketing]
    required_classes = %w[environmental sustainability social governance nutrition health limitation]
    missing_surfaces = required_surfaces - Array(scope["required_surfaces"])
    missing_classes = required_classes - Array(scope["required_claim_classes"])
    unless missing_surfaces.empty?
      violations << "#{label}: missing required surfaces #{missing_surfaces.join(', ')}"
    end
    unless missing_classes.empty?
      violations << "#{label}: missing claim classes #{missing_classes.join(', ')}"
    end
  end

  def validate_health_boundary(inventory, label)
    health = inventory.fetch("health_boundary", {})
    expected = {
      "display_title" => "Nährwert-Hinweis",
      "presentation" => "neutral_source_information_only",
      "score_or_progress_indicator_allowed" => false,
      "medical_or_individual_advice_allowed" => false,
      "beneficial_characterization_allowed_without_authorized_claim" => false,
      "eu_register_check_required_for_health_claim" => true,
      "source_and_retrieval_context_required" => true,
      "required_disclosure" => "Keine medizinische oder individuelle Ernährungsberatung.",
    }
    expected.each do |field, value|
      unless health[field] == value
        violations << "#{label}: health_boundary.#{field} must be #{value.inspect}"
      end
    end
    if Array(health["prohibited_runtime_terms"]).empty?
      violations << "#{label}: prohibited_runtime_terms must not be empty"
    end
  end

  def validate_claim_records(inventory, label)
    claims = Array(inventory["claims"])
    violations << "#{label}: claims must not be empty" if claims.empty?
    duplicate_ids(claims).each do |id|
      violations << "#{label}: duplicate claim id #{id}"
    end
    claims.each_with_index do |claim, index|
      item_label = "#{label}: claims[#{index}]"
      require_fields(
        claim,
        %w[id surface element claim_classes explicit_or_implied current_status release_status methodology_version confidence_rule],
        item_label,
      )
      unless claim.key?("evidence_refs")
        violations << "#{item_label}: missing evidence_refs"
      end
      unless claim["id"].to_s.match?(/\ACLM-(APP|STORE|WEB)-\d{3}\z/)
        violations << "#{item_label}: invalid claim id #{claim['id'].inspect}"
      end
      Array(claim["evidence_refs"]).each do |reference|
        unless File.exist?(path(reference.to_s))
          violations << "#{claim['id']}: evidence reference is missing: #{reference}"
        end
      end
    end

    surfaces = claims.map { |claim| claim["surface"] }.compact.uniq
    classes = claims.flat_map { |claim| Array(claim["claim_classes"]) }.uniq
    missing_surfaces = Array(inventory.dig("scope_contract", "required_surfaces")) - surfaces
    missing_classes = Array(inventory.dig("scope_contract", "required_claim_classes")) - classes
    unless missing_surfaces.empty?
      violations << "#{label}: no claim record for #{missing_surfaces.join(', ')}"
    end
    unless missing_classes.empty?
      violations << "#{label}: no claim record for classes #{missing_classes.join(', ')}"
    end
  end

  def validate_claim_runtime(inventory)
    runtime = Dir
      .glob(path("esg_app/lib/**/*.dart"))
      .map { |file| File.read(file, encoding: "UTF-8") }
      .join("\n")
    Array(inventory.dig("health_boundary", "prohibited_runtime_terms")).each do |term|
      pattern = /(?<![[:alpha:]])#{Regexp.escape(term)}(?![[:alpha:]])/i
      if runtime.match?(pattern)
        violations << "app runtime: prohibited health or benefit phrase #{term.inspect}"
      end
    end

    product_model = read("esg_app/lib/models/product.dart")
    score_widgets = read("esg_app/lib/widgets/score_widgets.dart")
    nutrition_section = score_widgets[/class SecondaryInfoCard.*?(?=\nclass MethodFootnote)/m].to_s
    if product_model.include?("secondaryPosition")
      violations << "product model: secondaryPosition must not exist"
    end
    if nutrition_section.include?("LinearProgressIndicator")
      violations << "nutrition presentation: progress indicators are prohibited"
    end
    unless nutrition_section.include?("Nährwert-Hinweis")
      violations << "nutrition presentation: missing title"
    end
    disclosure = inventory.dig("health_boundary", "required_disclosure").to_s
    unless nutrition_section.include?(disclosure)
      violations << "nutrition presentation: required disclosure is missing"
    end
  end

  def validate_claim_profile(inventory, label)
    enabled = inventory.dig("public_activation", "enabled")
    if @profile == "development"
      unless enabled == false
        violations << "#{label}: public claims must remain disabled in development"
      end
      return
    end

    unless enabled == true
      violations << "#{label}: public activation must be explicit for #{@profile}"
    end
    unless inventory.dig("public_activation", "claim_set_release_status") == "approved"
      violations << "#{label}: claim set is not approved for #{@profile}"
    end

    {
      "legal" => "legal_review",
      "subject_matter" => "subject_matter_review",
    }.each do |review_name, contract_name|
      review = inventory.dig("reviews", review_name) || {}
      unless review["status"] == "approved"
        violations << "#{label}: #{review_name} review is not approved"
      end
      validate_evidence(
        review["evidence"],
        inventory.dig("evidence_contracts", contract_name) || {},
        "#{label}: #{review_name}",
        inventory_relative: label,
      )
    end

    Array(inventory["claims"]).each do |claim|
      next if %w[approved required].include?(claim["release_status"])

      violations << "#{claim['id']}: release status #{claim['release_status'].inspect} is not approved"
    end
    Array(inventory["claims"]).each do |claim|
      if Array(claim["evidence_refs"]).empty?
        violations << "#{claim['id']}: approved release claim requires evidence_refs"
      end
    end
  end

  def validate_privacy
    relative = "docs/project/compliance/privacy-data-inventory.yaml"
    inventory = load_yaml(relative)
    require_fields(
      inventory,
      %w[schema_version last_reviewed owner status controller current_feature_state enforcement_profiles reviews evidence_contracts processing_activities data_flow_contract retention_contract data_subject_rights dpia remote_release_blocks primary_sources],
      relative,
    )
    return if inventory.empty?

    require_source_ids(inventory["primary_sources"], relative)
    validate_privacy_records(inventory, relative)
    validate_privacy_runtime(inventory)
    validate_privacy_profile(inventory, relative)
  end

  def validate_privacy_records(inventory, label)
    activities = Array(inventory["processing_activities"])
    violations << "#{label}: processing_activities must not be empty" if activities.empty?
    duplicate_ids(activities).each do |id|
      violations << "#{label}: duplicate processing id #{id}"
    end
    required = %w[id enabled data_type data_subject personal_data_assessment source purpose necessity processing_location region legal_basis_candidate legal_basis_status retention deletion apple_data_type linked_to_user tracking safeguards]
    activities.each_with_index do |activity, index|
      require_fields(activity, required, "#{label}: processing_activities[#{index}]")
      unless activity.key?("recipients")
        violations << "#{label}: processing_activities[#{index}]: missing recipients"
      end
      unless activity["id"].to_s.match?(/\APRV-\d{3}\z/)
        violations << "#{label}: invalid processing id #{activity['id'].inspect}"
      end
    end

    expected_ids = %w[PRV-001 PRV-002 PRV-003 PRV-004 PRV-005 PRV-006 PRV-007]
    missing_ids = expected_ids - activities.map { |activity| activity["id"] }
    unless missing_ids.empty?
      violations << "#{label}: missing processing activities #{missing_ids.join(', ')}"
    end

    network = activities.find { |activity| activity["id"] == "PRV-003" } || {}
    unless network["personal_data_assessment"].to_s.include?("ip_address")
      violations << "#{label}: direct lookup must expose possible IP-address processing"
    end
    if @profile == "development" && !network["retention"].to_s.include?("unknown_release_blocker")
      violations << "#{label}: development inventory must expose provider-retention uncertainty"
    end
  end

  def validate_privacy_runtime(inventory)
    features = inventory.fetch("current_feature_state", {})
    enabled = %w[camera_enabled direct_open_food_facts_lookup_enabled]
    disabled = %w[accounts_enabled analytics_enabled tracking_enabled location_enabled crash_reporting_sdk_enabled user_generated_content_enabled]
    enabled.each do |field|
      violations << "privacy feature state: #{field} must be true" unless features[field] == true
    end
    disabled.each do |field|
      violations << "privacy feature state: #{field} must be false" unless features[field] == false
    end
    if %w[development external_beta].include?(@profile) && features["remote_backend_enabled"] != false
      violations << "privacy feature state: remote_backend_enabled must be false for #{@profile}"
    end

    scanner = read("esg_app/lib/screens/scanner_screen.dart")
    service = read("esg_app/lib/services/open_food_facts_service.dart")
    repository = read("esg_app/lib/services/product_repository.dart")
    manifest = read("esg_app/ios/Runner/PrivacyInfo.xcprivacy")
    privacy = read("docs/privacy.md")
    flow = read("docs/project/compliance/privacy-data-flow.md")

    violations << "scanner: returnImage must be false" unless scanner.match?(/returnImage:\s*false/)
    unless service.include?("world.openfoodfacts.org") && service.include?("Uri.https")
      violations << "Open Food Facts service: expected direct HTTPS boundary is missing"
    end
    unless repository.match?(/_recentProducts\.length\s*>\s*10/) && repository.include?("removeLast")
      violations << "product repository: ten-item volatile retention bound is missing"
    end
    unless manifest.match?(/<key>NSPrivacyTracking<\/key>\s*<false\/>/m)
      violations << "privacy manifest: tracking must remain false"
    end
    if privacy.match?(/keine personenbezogenen daten (mitgesendet|übertragen)/i)
      violations << "docs/privacy.md: direct lookup must not deny possible network personal data"
    end
    ["IP-Adresse", "Open Food Facts", "Laufzeitspeicher"].each do |marker|
      unless privacy.include?(marker)
        violations << "docs/privacy.md: missing current-flow marker #{marker.inspect}"
      end
    end
    ["Current Data Flow", "DPIA Decision Path"].each do |marker|
      unless flow.include?(marker)
        violations << "privacy-data-flow.md: missing #{marker.inspect}"
      end
    end
  end

  def validate_privacy_profile(inventory, label)
    if @profile == "development"
      unless inventory.dig("current_feature_state", "remote_backend_enabled") == false
        violations << "#{label}: remote backend must remain disabled in development"
      end
      return
    end

    controller = inventory.fetch("controller", {})
    unless controller["postal_address_status"] == "complete"
      violations << "#{label}: controller postal address is incomplete"
    end

    validate_privacy_review(inventory, "direct_lookup_roles_and_legal_basis", "legal_review", "approved", label)
    validate_privacy_review(inventory, "public_privacy_disclosure", "privacy_disclosure_review", "approved", label)
    validate_privacy_review(inventory, "app_privacy_details", "app_privacy_details", "completed", label)
    validate_dpia_evidence(inventory, label)
    validate_enabled_processing_activities(inventory, label)

    privacy = read("docs/privacy.md")
    if privacy.match?(/Entwurf|Stub/i)
      violations << "docs/privacy.md: draft privacy text cannot pass #{@profile}"
    end

    remote_enabled = inventory.dig("current_feature_state", "remote_backend_enabled") == true
    if @profile == "remote_backend" && !remote_enabled
      violations << "#{label}: remote_backend profile requires repository-backed activation"
    end
    return unless @profile == "remote_backend" || remote_enabled

    validate_privacy_review(inventory, "remote_legal_basis", "legal_review", "approved", label)
    validate_privacy_review(inventory, "processor_contracts", "processor_review", "approved", label)
    validate_privacy_review(inventory, "rights_operations", "rights_verification", "verified", label)
  end

  def validate_enabled_processing_activities(inventory, label)
    Array(inventory["processing_activities"]).each do |activity|
      next unless activity["enabled"] == true

      %w[region legal_basis_status retention deletion].each do |field|
        value = activity[field].to_s.downcase
        marker = UNRESOLVED_PROCESSING_MARKERS.find { |candidate| value.include?(candidate) }
        next unless marker

        violations << "#{label}: #{activity['id']} #{field} remains unresolved (#{marker})"
      end
    end
  end

  def validate_privacy_review(inventory, review_name, contract_name, expected_status, label)
    review = inventory.dig("reviews", review_name) || {}
    unless review["status"] == expected_status
      violations << "#{label}: #{review_name} status must be #{expected_status}"
    end
    validate_evidence(
      review["evidence"],
      inventory.dig("evidence_contracts", contract_name) || {},
      "#{label}: #{review_name}",
      inventory_relative: label,
    )
  end

  def validate_dpia_evidence(inventory, label)
    dpia = inventory.dig("dpia", "remote_or_beta_scope") || {}
    unless dpia["decision_status"] == "approved"
      violations << "#{label}: DPIA screening decision is not approved"
    end
    validate_evidence(
      dpia["evidence"],
      inventory.dig("evidence_contracts", "dpia_screening") || {},
      "#{label}: DPIA screening",
      inventory_relative: label,
    )
  end

  def validate_evidence(relative, contract, label, inventory_relative:)
    evidence = load_evidence(relative, label)
    return if evidence.empty?

    unless evidence["evidence_type"] == contract["evidence_type"]
      violations << "#{label}: evidence_type must be #{contract['evidence_type'].inspect}"
    end
    contract.fetch("required_values", {}).each do |field, expected|
      unless evidence[field] == expected
        violations << "#{label}: #{field} must be #{expected.inspect}"
      end
    end
    require_fields(evidence, Array(contract["required_fields"]), label)
    Array(contract["digest_fields"]).each do |field|
      unless evidence[field].to_s.match?(SHA256_PATTERN)
        violations << "#{label}: #{field} must be a lowercase SHA-256"
      end
    end

    inventory_digest_field = if evidence.key?("claim_inventory_sha256")
                               "claim_inventory_sha256"
                             else
                               "privacy_inventory_sha256"
                             end
    if evidence[inventory_digest_field]
      actual = Digest::SHA256.file(path(inventory_relative)).hexdigest
      unless evidence[inventory_digest_field] == actual
        violations << "#{label}: #{inventory_digest_field} does not match inventory"
      end
    end

    {
      "document_sha256" => "document_path",
      "artifact_sha256" => "artifact_path",
      "contract_sha256" => "contract_path",
    }.each do |digest_field, path_field|
      next unless evidence[digest_field]

      artifact = safe_repo_path(evidence[path_field], label)
      next unless artifact
      unless File.file?(artifact)
        violations << "#{label}: referenced artifact is missing: #{evidence[path_field]}"
        next
      end
      actual = Digest::SHA256.file(artifact).hexdigest
      unless evidence[digest_field] == actual
        violations << "#{label}: #{digest_field} does not match #{path_field}"
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    profile: "development",
    gate: "all",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--profile PROFILE", ClaimsPrivacyBoundaryValidator::PROFILES) do |value|
      options[:profile] = value
    end
    parser.on("--gate GATE", ClaimsPrivacyBoundaryValidator::GATES) do |value|
      options[:gate] = value
    end
  end.parse!

  validator = ClaimsPrivacyBoundaryValidator.new(**options)
  if validator.run
    puts "#{options[:gate]} boundary gate PASS (#{options[:profile]})"
    exit 0
  end

  warn "#{options[:gate]} boundary gate FAIL (#{options[:profile]}):"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
