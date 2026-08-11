#!/usr/bin/env ruby

require "date"
require "optparse"
require "yaml"

class DataLicenseCompositionValidator
  PROFILES = %w[development remote_backend release_candidate].freeze

  def initialize(repo_root:, profile:, policy: nil)
    @repo_root = repo_root
    @profile = profile
    @policy = policy || load_yaml("docs/project/data/license-composition-policy.yaml")
  end

  def violations
    findings = []
    unless PROFILES.include?(@profile)
      return ["Unknown data-license profile #{@profile.inspect}"]
    end

    validate_policy_structure(findings)
    validate_source_contracts(findings)
    validate_composition_scenarios(findings)
    validate_architecture_contract(findings)
    validate_source_register(findings)
    validate_compliance_sources(findings)
    validate_database_markers(findings)
    validate_app_attribution(findings)
    validate_license_document(findings)
    validate_profile(findings)
    findings
  end

  private

  def load_yaml(relative_path)
    YAML.safe_load(
      File.read(File.join(@repo_root, relative_path)),
      permitted_classes: [Date],
      aliases: false,
    )
  end

  def read(relative_path)
    File.read(File.join(@repo_root, relative_path), encoding: "UTF-8")
  end

  def evidence_file?(reference)
    return false if reference.to_s.strip.empty?

    path = File.expand_path(reference.to_s, @repo_root)
    return false unless path.start_with?("#{@repo_root}/") && File.file?(path)

    root = File.realpath(@repo_root)
    File.realpath(path).start_with?("#{root}/")
  rescue Errno::ENOENT
    false
  end

  def valid_evidence_manifest?(reference, contract_id)
    return false unless evidence_file?(reference)

    manifest = YAML.safe_load(
      File.read(File.expand_path(reference.to_s, @repo_root)),
      permitted_classes: [Date],
      aliases: false,
    )
    contract = @policy.dig("evidence_contracts", contract_id)
    return false unless manifest.is_a?(Hash) && contract.is_a?(Hash)
    return false unless manifest["evidence_type"] == contract["evidence_type"]

    required_values = contract.fetch("required_values", {})
    return false unless required_values.all? do |field, expected|
      manifest[field] == expected
    end

    required_fields = Array(contract["required_fields"])
    return false unless required_fields.all? do |field|
      evidence_value_present?(manifest[field])
    end

    digest = manifest[contract["digest_field"]]
    digest.to_s.match?(/\A[0-9a-f]{64}\z/)
  rescue Errno::ENOENT, Psych::Exception
    false
  end

  def evidence_value_present?(value)
    case value
    when Array, Hash
      !value.empty?
    else
      !value.to_s.strip.empty?
    end
  end

  def validate_policy_structure(findings)
    %w[
      schema_version
      last_reviewed
      owner
      status
      legal_review
      evidence_contracts
      enforcement_profiles
      source_contracts
      composition_scenarios
      architecture_contract
      release_blocks
      primary_sources
    ].each do |field|
      findings << "License policy is missing #{field}" unless @policy.key?(field)
    end

    findings << "License policy is not accepted for local development" unless (
      @policy["status"] == "accepted_for_local_development"
    )
    findings << "Qualified legal review must remain explicit" unless (
      @policy.dig("legal_review", "reviewer_requirement") ==
        "qualified_data_licensing_counsel"
    )
  end

  def validate_source_contracts(findings)
    expected = {
      "open-food-facts" => {
        "database_license" => "ODbL-1.0",
        "contents_license" => "DbCL-1.0",
        "image_license" => "CC-BY-SA-3.0",
        "attribution" => "Open Food Facts contributors",
        "license_partition" => "off-odbl",
        "raw_cache_policy" => "isolated_source_only",
        "public_redistribution_policy" => "odbl_share_alike",
      },
      "agribalyse" => {
        "database_license" => "Etalab-2.0",
        "contents_license" => "Etalab-2.0",
        "license_partition" => "agribalyse-etalab",
        "raw_cache_policy" => "dedicated_store_required",
        "public_redistribution_policy" => "attribution_required",
      },
      "gepa-product-declarations" => {
        "database_license" => "Proprietary-publication",
        "contents_license" => "Proprietary-publication",
        "license_partition" => "gepa-restricted",
        "raw_cache_policy" => "forbidden",
        "public_redistribution_policy" => "prohibited",
      },
    }

    expected.each do |source_id, fields|
      source = @policy.dig("source_contracts", source_id)
      unless source.is_a?(Hash)
        findings << "Missing source contract #{source_id}"
        next
      end
      fields.each do |field, value|
        unless source[field] == value
          findings << "#{source_id}.#{field} must equal #{value.inspect}"
        end
      end
    end

    off = @policy.dig("source_contracts", "open-food-facts") || {}
    %w[database_license_url contents_license_url image_license_url].each do |field|
      findings << "open-food-facts.#{field} must be an HTTPS URL" unless (
        off[field].to_s.start_with?("https://")
      )
    end
  end

  def validate_composition_scenarios(findings)
    expected = {
      "direct_off_api_result" => "produced_work",
      "off_raw_or_normalized_cache" => "derivative_database",
      "source_partitioned_evidence_index" => "collective_database_candidate",
      "score_snapshot_and_result_ui" => "produced_work_candidate",
    }
    expected.each do |scenario, classification|
      unless @policy.dig(
        "composition_scenarios",
        scenario,
        "conservative_classification",
      ) == classification
        findings << "#{scenario} must be classified as #{classification}"
      end
      conditions = Array(
        @policy.dig("composition_scenarios", scenario, "conditions"),
      )
      findings << "#{scenario} must define conditions" if conditions.empty?
    end

    unless @policy.dig(
      "composition_scenarios",
      "off_raw_or_normalized_cache",
      "current_status",
    ) == "blocked_for_remote_backend"
      findings << "OFF cache must remain blocked for the remote backend"
    end
  end

  def validate_architecture_contract(findings)
    off_cache = @policy.dig("architecture_contract", "off_cache") || {}
    unless off_cache["allowed_sources"] == ["open-food-facts"]
      findings << "OFF cache allowed_sources must contain only open-food-facts"
    end
    unless off_cache["external_source_policy"] == "dedicated_store_required"
      findings << "External product sources must require a dedicated store"
    end
    unless off_cache["database_trigger_required"] ==
           "enforce_cached_product_license_boundary"
      findings << "OFF cache boundary trigger is not declared"
    end

    evidence = @policy.dig("architecture_contract", "normalized_evidence") || {}
    findings << "Normalized evidence must prohibit raw payloads" unless (
      evidence["raw_payloads_allowed"] == false
    )
    findings << "Normalized evidence must require source IDs" unless (
      evidence["source_id_required"] == true
    )

    images = @policy.dig("architecture_contract", "images") || {}
    findings << "Persistent remote image cache must remain disabled" unless (
      images["persistent_remote_cache_allowed"] == false
    )
    findings << "Displayed images require attribution" unless (
      images["attribution_required_when_displayed"] == true
    )
  end

  def validate_source_register(findings)
    register = load_yaml("docs/project/data/source-register.yaml")
    sources = Array(register["sources"]).to_h { |source| [source["id"], source] }
    @policy.fetch("source_contracts", {}).each do |source_id, contract|
      source = sources[source_id]
      unless source
        findings << "Source register is missing #{source_id}"
        next
      end
      {
        "database" => "database_license",
        "contents" => "contents_license",
        "images" => "image_license",
        "attribution" => "attribution",
        "license_partition" => "license_partition",
        "raw_cache_policy" => "raw_cache_policy",
        "public_redistribution_policy" => "public_redistribution_policy",
      }.each do |register_field, contract_field|
        next unless contract.key?(contract_field)
        unless source.dig("license", register_field) == contract[contract_field]
          findings << "Source register mismatch for #{source_id}.#{register_field}"
        end
      end
    end
  end

  def validate_compliance_sources(findings)
    register = load_yaml("docs/project/compliance/source-register.yaml")
    source_ids = Array(register["sources"]).map { |source| source["id"] }
    %w[OFF-LICENSE ODC-ODBL ODC-DBCL CC-BY-SA-3 ETALAB-OL-2].each do |id|
      findings << "Compliance source register is missing #{id}" unless source_ids.include?(id)
    end
  end

  def validate_database_markers(findings)
    sql = Dir.glob(File.join(@repo_root, "supabase/migrations/*.sql"))
      .sort
      .map { |path| File.read(path) }
      .join("\n")
      .downcase
    markers = {
      "content license column" => "add column if not exists content_license",
      "image license column" => "add column if not exists image_license",
      "database license URL column" =>
        "add column if not exists database_license_url",
      "content license URL column" =>
        "add column if not exists content_license_url",
      "image license URL column" => "add column if not exists image_license_url",
      "license partition column" => "add column if not exists license_partition",
      "raw cache policy column" => "add column if not exists raw_cache_policy",
      "OFF DbCL metadata" => "'dbcl-1.0'",
      "OFF image license metadata" => "'cc-by-sa-3.0'",
      "OFF cache trigger" => "enforce_cached_product_license_boundary",
      "external cache rejection" =>
        "external product data requires a dedicated license store",
    }
    markers.each do |name, marker|
      findings << "Database migration is missing #{name}" unless sql.include?(marker)
    end
  end

  def validate_app_attribution(findings)
    model = read("esg_app/lib/models/esg_evidence.dart")
    widget = read("esg_app/lib/widgets/score_widgets.dart")
    {
      "OFF database license" => "datasetLicense: 'ODbL-1.0'",
      "OFF contents license" => "contentLicense: 'DbCL-1.0'",
      "OFF image license" => "imageLicense: 'CC-BY-SA-3.0'",
      "OFF ODbL URI" =>
        "https://opendatacommons.org/licenses/odbl/1-0/",
      "OFF image license URI" =>
        "https://creativecommons.org/licenses/by-sa/3.0/",
      "OFF contributor attribution" =>
        "attribution: 'Open Food Facts contributors'",
      "OFF public-use notice" =>
        "Enthält Informationen aus Open Food Facts",
    }.each do |name, marker|
      findings << "App model is missing #{name}" unless model.include?(marker)
    end
    %w[Datenquellen-Lizenz: Inhalte: Produktbilder: databaseLicenseUrl contentLicenseUrl].each do |marker|
      findings << "Result attribution UI is missing #{marker}" unless widget.include?(marker)
    end
  end

  def validate_license_document(findings)
    document = read("docs/licenses.md")
    %w[ODbL DbCL CC\ BY-SA\ 3.0 Produced\ Work Derivative\ Database Collective\ Database G-DATA-LICENSE].each do |marker|
      normalized = marker.tr("\\", "")
      findings << "docs/licenses.md is missing #{normalized}" unless document.include?(normalized)
    end
  end

  def validate_profile(findings)
    remote_enabled = @policy.dig(
      "architecture_contract",
      "remote_backend",
      "enabled",
    )
    legal_review = @policy.dig("legal_review", "status")

    if @profile == "development"
      findings << "Development profile requires remote backend disabled" unless remote_enabled == false
      return
    end

    findings << "#{@profile} requires remote backend enabled" unless remote_enabled == true
    activation_evidence = @policy.dig(
      "architecture_contract",
      "remote_backend",
      "activation_evidence",
    )
    unless valid_evidence_manifest?(activation_evidence, "remote_activation")
      findings << "#{@profile} requires valid repository-backed remote activation evidence"
    end
    findings << "#{@profile} requires approved qualified legal review" unless legal_review == "approved"
    evidence = @policy.dig("legal_review", "evidence")
    unless valid_evidence_manifest?(evidence, "legal_review")
      findings << "#{@profile} requires valid repository-backed legal-review evidence"
    end

    export_status = @policy.dig(
      "architecture_contract",
      "share_alike_export",
      "status",
    )
    deletion_status = @policy.dig(
      "architecture_contract",
      "correction_and_deletion",
      "status",
    )
    findings << "#{@profile} requires implemented share-alike export" unless export_status == "implemented"
    findings << "#{@profile} requires implemented correction and deletion" unless deletion_status == "implemented"
    export_evidence = @policy.dig(
      "architecture_contract",
      "share_alike_export",
      "implementation_evidence",
    )
    deletion_evidence = @policy.dig(
      "architecture_contract",
      "correction_and_deletion",
      "implementation_evidence",
    )
    unless valid_evidence_manifest?(export_evidence, "share_alike_export")
      findings << "#{@profile} requires valid repository-backed share-alike export evidence"
    end
    unless valid_evidence_manifest?(deletion_evidence, "correction_and_deletion")
      findings << "#{@profile} requires valid repository-backed correction and deletion evidence"
    end

    return unless @profile == "release_candidate"

    image_review = @policy.dig(
      "architecture_contract",
      "images",
      "reuse_review_status",
    )
    image_evidence = @policy.dig(
      "architecture_contract",
      "images",
      "reuse_review_evidence",
    )
    findings << "release_candidate requires approved image reuse review" unless image_review == "approved"
    unless valid_evidence_manifest?(image_evidence, "image_reuse_review")
      findings << "release_candidate requires valid repository-backed image-review evidence"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    profile: ENV.fetch("DATA_LICENSE_PROFILE", "development"),
  }
  OptionParser.new do |parser|
    parser.on("--profile PROFILE") { |profile| options[:profile] = profile }
  end.parse!

  repo_root = File.expand_path("../..", __dir__)
  validator = DataLicenseCompositionValidator.new(
    repo_root: repo_root,
    profile: options[:profile],
  )
  violations = validator.violations
  if violations.empty?
    puts "Data license composition OK: #{options[:profile]} profile"
    exit 0
  end

  warn "Data license composition validation failed (#{options[:profile]}):"
  violations.each { |violation| warn "- #{violation}" }
  exit 1
end
