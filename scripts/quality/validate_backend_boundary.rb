#!/usr/bin/env ruby

require "date"
require "digest"
require "find"
require "optparse"
require "set"
require "yaml"

class BackendBoundaryValidator
  PROFILES = %w[development remote_backend release_candidate].freeze
  SHA256_PATTERN = /\A[0-9a-f]{64}\z/.freeze
  REQUIRED_THREAT_CATEGORIES = %w[
    spoofing
    tampering
    repudiation
    information_disclosure
    denial_of_service
    elevation_of_privilege
  ].freeze
  EXPECTED_BOUNDARIES = %w[TB-01 TB-02 TB-03 TB-04 TB-05 TB-06].freeze
  EXPECTED_THREATS = (1..12).map { |number| format("THR-%03d", number) }.freeze
  EXPECTED_ABUSE_CASES = (1..8).map { |number| format("ABUSE-%03d", number) }.freeze
  REVIEW_CONTRACTS = %w[
    environment_activation
    writer_security
    operational_readiness
  ].freeze
  RELEASE_REVIEW_CONTRACT = "release_security"

  attr_reader :violations

  def initialize(repo_root:, profile: "development")
    @repo_root = File.expand_path(repo_root)
    @profile = profile
    @violations = []
    @threat_path = "docs/project/security/backend-threat-model.yaml"
    @environment_path =
      "docs/project/security/eu-supabase-environment-contract.yaml"
  end

  def run
    @source_ids = load_source_ids
    @threat_model = load_yaml(@threat_path)
    @environment = load_yaml(@environment_path)
    validate_threat_model
    validate_environment_contract
    validate_repository_boundary
    validate_profile
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

  def duplicate_ids(records)
    counts = records.each_with_object(Hash.new(0)) do |record, result|
      result[record["id"]] += 1 if record["id"]
    end
    counts.select { |_id, count| count > 1 }.keys
  end

  def require_source_ids(ids, label)
    Array(ids).each do |id|
      violations << "#{label}: unknown source #{id}" unless @source_ids.include?(id)
    end
  end

  def validate_threat_model
    label = @threat_path
    require_fields(
      @threat_model,
      %w[schema_version last_reviewed owner status scope methodology assumptions assets actors trust_boundaries data_flows threats abuse_cases residual_risks activation_boundary related primary_sources],
      label,
    )
    return if @threat_model.empty?

    unless @threat_model["status"] == "accepted_for_definition_of_ready"
      violations << "#{label}: status must be accepted_for_definition_of_ready"
    end
    require_source_ids(@threat_model["primary_sources"], label)

    assets = Array(@threat_model["assets"])
    actors = Array(@threat_model["actors"])
    boundaries = Array(@threat_model["trust_boundaries"])
    flows = Array(@threat_model["data_flows"])
    threats = Array(@threat_model["threats"])
    abuse_cases = Array(@threat_model["abuse_cases"])

    validate_records(assets, "AST", %w[name security_properties], label)
    validate_records(actors, "ACT", %w[name trust], label)
    validate_records(
      boundaries,
      "TB",
      %w[name authentication authorization],
      label,
    )
    validate_records(flows, "FLOW", %w[from to data state], label)
    validate_records(
      abuse_cases,
      "ABUSE",
      %w[scenario expected_result],
      label,
    )

    boundary_ids = boundaries.map { |boundary| boundary["id"] }
    missing_boundaries = EXPECTED_BOUNDARIES - boundary_ids
    unless missing_boundaries.empty?
      violations << "#{label}: missing trust boundaries #{missing_boundaries.join(', ')}"
    end

    asset_ids = assets.map { |asset| asset["id"] }.to_set
    threat_ids = threats.map { |threat| threat["id"] }
    missing_threats = EXPECTED_THREATS - threat_ids
    unless missing_threats.empty?
      violations << "#{label}: missing threats #{missing_threats.join(', ')}"
    end
    duplicate_ids(threats).each do |id|
      violations << "#{label}: duplicate threat id #{id}"
    end
    threats.each_with_index do |threat, index|
      threat_label = "#{label}: threats[#{index}]"
      require_fields(
        threat,
        %w[id category title severity boundary assets attack controls verification implementation_status],
        threat_label,
      )
      unless threat["id"].to_s.match?(/\ATHR-\d{3}\z/)
        violations << "#{threat_label}: invalid id #{threat['id'].inspect}"
      end
      unless REQUIRED_THREAT_CATEGORIES.include?(threat["category"])
        violations << "#{threat['id']}: invalid STRIDE category #{threat['category'].inspect}"
      end
      unless %w[medium high critical].include?(threat["severity"])
        violations << "#{threat['id']}: invalid severity #{threat['severity'].inspect}"
      end
      unless boundary_ids.include?(threat["boundary"])
        violations << "#{threat['id']}: unknown boundary #{threat['boundary'].inspect}"
      end
      Array(threat["assets"]).each do |asset_id|
        violations << "#{threat['id']}: unknown asset #{asset_id}" unless asset_ids.include?(asset_id)
      end
      violations << "#{threat['id']}: controls must not be empty" if Array(threat["controls"]).empty?
      if Array(threat["verification"]).empty?
        violations << "#{threat['id']}: verification must not be empty"
      end
    end

    categories = threats.map { |threat| threat["category"] }.uniq
    missing_categories = REQUIRED_THREAT_CATEGORIES - categories
    unless missing_categories.empty?
      violations << "#{label}: missing STRIDE categories #{missing_categories.join(', ')}"
    end
    missing_abuse_cases = EXPECTED_ABUSE_CASES - abuse_cases.map { |item| item["id"] }
    unless missing_abuse_cases.empty?
      violations << "#{label}: missing abuse cases #{missing_abuse_cases.join(', ')}"
    end

    activation = @threat_model.fetch("activation_boundary", {})
    unless activation["remote_backend_enabled"] == false &&
           activation["implementation_state"] == "local_implementation_validated"
      violations << "#{label}: threat-model activation boundary must remain locally validated and remotely disabled"
    end
  end

  def validate_environment_contract
    label = @environment_path
    require_fields(
      @environment,
      %w[schema_version last_reviewed owner status implementation_state remote_backend_enabled threat_model_ref purpose environment_isolation environments key_and_identity_contract writer_contract resource_protection read_contract audit_contract secret_lifecycle incident_contract implementation_evidence activation_profiles reviews evidence_contracts remote_activation_blocks primary_sources],
      label,
    )
    return if @environment.empty?

    unless @environment["status"] == "accepted_for_definition_of_ready"
      violations << "#{label}: status must be accepted_for_definition_of_ready"
    end
    unless @environment["threat_model_ref"] == @threat_path
      violations << "#{label}: threat_model_ref must point to #{@threat_path}"
    end
    require_source_ids(@environment["primary_sources"], label)

    isolation = @environment.fetch("environment_isolation", {})
    {
      "separate_project_per_environment" => true,
      "production_data_in_non_production" => "prohibited",
      "cross_environment_keys" => "prohibited",
      "linked_remote_reset" => "prohibited",
    }.each do |field, expected|
      unless isolation[field] == expected
        violations << "#{label}: environment_isolation.#{field} must be #{expected.inspect}"
      end
    end

    environments = Array(@environment["environments"])
    validate_records(
      environments,
      "ENV",
      %w[status project_class region data_classification],
      label,
      id_pattern: /\A(local|development|staging|production)\z/,
    )
    environment_ids = environments.map { |environment| environment["id"] }
    missing = %w[local development staging production] - environment_ids
    violations << "#{label}: missing environments #{missing.join(', ')}" unless missing.empty?
    development = environments.find { |environment| environment["id"] == "development" } || {}
    unless development["region"] == "eu-central-1" &&
           development["personal_data_allowed"] == false
      violations << "#{label}: development must use eu-central-1 without personal data"
    end

    validate_identity_contract(label)
    validate_writer_contract(label)
    validate_resource_contract(label)
    validate_read_audit_and_operations(label)
    validate_local_implementation_evidence(label)
  end

  def validate_local_implementation_evidence(label)
    evidence = @environment.fetch("implementation_evidence", {})
    expected = {
      "state" => "local_implementation_validated",
      "remote_deployment_evidence" => "absent",
      "writer_contract_tests" => "12/12 PASS",
      "database_tests" => "123/123 PASS",
      "flutter_cache_and_fallback_tests" => "15/15 PASS",
    }
    expected.each do |field, value|
      unless evidence[field] == value
        violations << "#{label}: implementation_evidence.#{field} must be #{value.inspect}"
      end
    end
    %w[artifacts validation_commands].each do |field|
      if Array(evidence[field]).empty?
        violations << "#{label}: implementation_evidence.#{field} must not be empty"
      end
    end
  end

  def validate_records(records, prefix, fields, label, id_pattern: nil)
    duplicate_ids(records).each do |id|
      violations << "#{label}: duplicate #{prefix} id #{id}"
    end
    pattern = id_pattern || /\A#{Regexp.escape(prefix)}-\d{2,3}\z/
    records.each_with_index do |record, index|
      record_label = "#{label}: #{prefix.downcase}[#{index}]"
      require_fields(record, ["id", *fields], record_label)
      unless record["id"].to_s.match?(pattern)
        violations << "#{record_label}: invalid id #{record['id'].inspect}"
      end
      fields.each do |field|
        if record[field].is_a?(Array) && record[field].empty?
          violations << "#{record['id']}: #{field} must not be empty"
        end
      end
    end
  end

  def validate_identity_contract(label)
    identity = @environment.fetch("key_and_identity_contract", {})
    mobile = identity.fetch("mobile_application", {})
    allowed = Array(mobile["allowed_key_types"])
    forbidden = Array(mobile["forbidden_key_types"])
    violations << "#{label}: Flutter must allow publishable keys only" unless allowed == ["publishable"]
    %w[secret service_role postgres_password management_api_token].each do |key_type|
      unless forbidden.include?(key_type)
        violations << "#{label}: Flutter forbidden keys must include #{key_type}"
      end
    end
    unless mobile["direct_writer_invocation_allowed"] == false
      violations << "#{label}: mobile writer invocation must be false"
    end

    writer = identity.fetch("trusted_writer", {})
    unless writer["repository_storage"] == "prohibited" &&
           writer["client_distribution"] == "prohibited"
      violations << "#{label}: writer credentials must be prohibited from repository and clients"
    end
  end

  def validate_writer_contract(label)
    writer = @environment.fetch("writer_contract", {})
    unless writer["client_invocation_allowed"] == false
      violations << "#{label}: trusted writer must reject client invocation"
    end
    unless Array(writer["allowed_invokers"]) == %w[scheduled_ingestion_job audited_operator_replay]
      violations << "#{label}: trusted writer invokers must remain narrowly allowlisted"
    end
    unless writer["authentication"] ==
           "separate_server_side_secret_per_named_invoker"
      violations << "#{label}: trusted writer must use a separate secret per named invoker"
    end
    input = writer.fetch("input_contract", {})
    unless input["barcode_pattern"] == "^[0-9]{8,14}$" &&
           input["maximum_batch_size"].to_i.between?(1, 25) &&
           input["maximum_request_bytes"].to_i.between?(1, 65_536) &&
           input["unknown_fields"] == "reject"
      violations << "#{label}: writer input bounds are incomplete or too broad"
    end
    upstream = writer.fetch("upstream_contract", {})
    unless Array(upstream["schemes"]) == ["https"] &&
           Array(upstream["methods"]) == ["GET"] &&
           Array(upstream["hosts"]) == ["world.openfoodfacts.org"] &&
           upstream["runtime_url_input"] == "prohibited" &&
           upstream["private_link_local_and_loopback_targets"] == "prohibited" &&
           upstream["request_timeout_seconds"].to_i.between?(1, 10) &&
           upstream["maximum_attempts"].to_i.between?(1, 3) &&
           upstream["maximum_response_bytes"].to_i.between?(1, 1_048_576)
      violations << "#{label}: upstream SSRF and resource bounds are incomplete"
    end
    idempotency = writer.fetch("idempotency_contract", {})
    required_keys = %w[source_id source_record_id source_observed_at payload_sha256]
    unless idempotency["required"] == true &&
           Array(idempotency["key_fields"]) == required_keys &&
           idempotency["out_of_order_behavior"] == "reject_older_observation"
      violations << "#{label}: writer idempotency contract is incomplete"
    end
    publication = writer.fetch("publication_contract", {})
    %w[validate_before_write publish_after_complete_transaction immutable_published_score_snapshots source_and_license_fields_server_controlled].each do |field|
      violations << "#{label}: publication_contract.#{field} must be true" unless publication[field] == true
    end
  end

  def validate_resource_contract(label)
    resources = @environment.fetch("resource_protection", {})
    bounds = {
      "writer_requests_per_minute_per_invoker" => 10,
      "writer_requests_per_minute_global" => 30,
      "upstream_requests_per_second" => 1,
      "daily_upstream_request_budget" => 500,
      "maximum_batch_concurrency" => 2,
    }
    bounds.each do |field, maximum|
      value = resources[field]
      unless value.is_a?(Numeric) && value.positive? && value <= maximum
        violations << "#{label}: resource_protection.#{field} must be between 1 and #{maximum}"
      end
    end
    circuit = resources.fetch("circuit_breaker", {})
    unless circuit["opens_after_consecutive_failures"].to_i.between?(1, 5) &&
           circuit["open_seconds"].to_i >= 60
      violations << "#{label}: circuit breaker is missing or too permissive"
    end
    unless resources.dig("cost_controls", "spend_cap_or_billing_alert_required") == true
      violations << "#{label}: spend cap or billing alert must be required"
    end
  end

  def validate_read_audit_and_operations(label)
    read_contract = @environment.fetch("read_contract", {})
    unless read_contract["maximum_products_per_barcode_query"] == 1 &&
           read_contract["explicit_columns_only"] == true &&
           read_contract["public_list_endpoint"] == "prohibited" &&
           read_contract["fresh_cache_only"] == true &&
           read_contract["published_evidence_and_scores_only"] == true &&
           read_contract["draft_methodology_visible"] == false
      violations << "#{label}: public read boundary is incomplete"
    end

    audit = @environment.fetch("audit_contract", {})
    required_audit_fields = %w[request_id idempotency_key actor_type action source_id target_record input_sha256 outcome status_code started_at completed_at correlation_id]
    unless audit["append_only"] == true &&
           audit["privileged_client_mutation"] == "prohibited" &&
           (required_audit_fields - Array(audit["required_fields"])).empty?
      violations << "#{label}: append-only writer audit contract is incomplete"
    end
    prohibited_audit_fields = %w[authorization_header secret_or_service_key raw_personal_payload full_upstream_response]
    unless (prohibited_audit_fields - Array(audit["prohibited_fields"])).empty?
      violations << "#{label}: audit redaction contract is incomplete"
    end

    lifecycle = @environment.fetch("secret_lifecycle", {})
    unless lifecycle["maximum_rotation_days"].to_i.between?(1, 180) &&
           lifecycle.dig("break_glass", "maximum_minutes").to_i.between?(1, 30) &&
           lifecycle.dig("break_glass", "post_event_rotation") == "required" &&
           lifecycle.dig("break_glass", "app_bypass") == "prohibited"
      violations << "#{label}: secret rotation or break-glass contract is incomplete"
    end
    incident = @environment.fetch("incident_contract", {})
    %w[detection_channels immediate_actions recovery_requires].each do |field|
      violations << "#{label}: incident_contract.#{field} must not be empty" if Array(incident[field]).empty?
    end
  end

  def validate_repository_boundary
    diagram = read("docs/project/security/backend-threat-model.md")
    %w[flowchart Publishable writer].each do |marker|
      unless diagram.include?(marker)
        violations << "backend-threat-model.md: missing #{marker.inspect}"
      end
    end
    adr = read("docs/project/decisions/0032-backend-security-boundary.yaml")
    unless adr.include?("G-BACKEND-BOUNDARY") && adr.include?("current_state: local_implementation_validated_remote_disabled")
      violations << "ADR 0032: backend gate or disabled current state is missing"
    end

    app_dir = path("esg_app/lib")
    forbidden = /service[_-]?role|supabase[_-]?secret|postgres[_-]?password|management[_-]?api[_-]?token/i
    mobile_writer_markers = /ingest-products|x-scanfair-writer-secret|claim_writer_capacity|publish_off_product|record_writer_outcome/i
    if Dir.exist?(app_dir)
      Find.find(app_dir) do |file|
        next unless File.file?(file)
        next unless File.extname(file) == ".dart"

        content = File.read(file)
        violations << "#{relative(file)}: privileged backend credential marker in Flutter code" if content.match?(forbidden)
        violations << "#{relative(file)}: trusted writer invocation marker in Flutter code" if content.match?(mobile_writer_markers)
      end
    else
      violations << "esg_app/lib: directory is missing"
    end

    migrations = Dir.glob(path("supabase/migrations/*.sql")).sort
    migration_text = migrations.map { |file| File.read(file) }.join("\n").downcase
    unless migration_text.include?("force row level security") &&
           migration_text.include?("revoke all on table")
      violations << "Supabase migrations: forced RLS and explicit revocation markers are required"
    end

    required_migration_markers = %w[
      create\ schema\ if\ not\ exists\ private
      get_fresh_cached_product
      revoke\ select\ on\ table\ public.cached_products
      claim_writer_capacity
      publish_off_product
      record_writer_outcome
      writer_idempotency_keys
      writer_audit_log
      writer_circuit_state
      reject_writer_audit_mutation
      record_writer_upstream_health
    ]
    required_migration_markers.each do |marker|
      readable = marker.tr("\\", "")
      unless migration_text.include?(readable)
        violations << "Supabase migrations: missing trusted-writer marker #{readable.inspect}"
      end
    end

    implementation_files = {
      "supabase/functions/_shared/writer_contract.mjs" => %w[
        authenticateWriter
        parseWriterRequest
        validateUpstreamUrl
        fetchOpenFoodFactsProduct
        maximumResponseBytes
      ],
      "supabase/functions/_shared/writer_contract.test.mjs" => %w[
        node:test
        writer_unauthorized
        upstream_not_allowed
        upstream_response_too_large
      ],
      "supabase/functions/ingest-products/index.ts" => %w[
        SCANFAIR_SCHEDULED_WRITER_SECRET
        SCANFAIR_OPERATOR_REPLAY_SECRET
        SCANFAIR_ENVIRONMENT
        SUPABASE_SERVICE_ROLE_KEY
        claim_writer_capacity
        publish_off_product
        record_writer_outcome
      ],
      "esg_app/lib/services/supabase_product_cache_service.dart" => %w[
        get_fresh_cached_product
        ProductCacheFailureType
        sb_publishable_
        expiresAt
      ],
      "esg_app/test/services/supabase_product_cache_service_test.dart" => %w[
        cache\ miss
        stale\ cache
        offline
      ],
      "supabase/tests/database/trusted_writer_cache_path.test.sql" => %w[
        plan(52)
        duplicate_existing
        rejected_older_observation
        writer\ circuit
        append-only
      ],
      "scripts/quality/run_edge_writer_integration_gate.sh" => %w[
        writer_unauthorized
        audited_operator_replay
        unknown_or_missing_fields
        G-BACKEND-EDGE
      ],
      ".github/workflows/quality-gates.yml" => %w[
        edge-writer-tests
        run_edge_writer_integration_gate.sh
        scanfair-backend-data-path-evidence
      ],
    }
    implementation_files.each do |file, markers|
      content = read(file)
      markers.each do |marker|
        readable = marker.tr("\\", "")
        unless content.include?(readable)
          violations << "#{file}: missing implementation marker #{readable.inspect}"
        end
      end
    end
  end

  def validate_profile
    enabled = @environment["remote_backend_enabled"] == true
    if @profile == "development"
      unless !enabled &&
             @environment["implementation_state"] == "local_implementation_validated"
        violations << "development: remote backend must remain disabled with a locally validated implementation"
      end
      return
    end

    if @profile == "release_candidate"
      validate_review(RELEASE_REVIEW_CONTRACT)
      return unless enabled
    end

    unless enabled && @environment["implementation_state"] == "deployed_to_eu_development"
      violations << "#{@profile}: remote backend must be enabled and deployed to EU development"
    end
    development = Array(@environment["environments"]).find do |environment|
      environment["id"] == "development"
    end || {}
    unless development["status"] == "active" &&
           development["region"] == "eu-central-1" &&
           development["dpa_status"] == "approved"
      violations << "#{@profile}: active eu-central-1 development environment with approved DPA is required"
    end

    REVIEW_CONTRACTS.each { |name| validate_review(name) }
  end

  def validate_review(name)
    review = @environment.dig("reviews", name) || {}
    unless review["status"] == "approved"
      violations << "#{@profile}: #{name} review must be approved"
    end
    validate_evidence(
      review["evidence"],
      @environment.dig("evidence_contracts", name) || {},
      "#{@profile}: #{name}",
    )
  end

  def validate_evidence(relative_path, contract, label)
    absolute = safe_repo_path(relative_path, label)
    return unless absolute
    unless File.file?(absolute)
      violations << "#{label}: evidence file is missing: #{relative_path}"
      return
    end
    evidence = YAML.safe_load(
      File.read(absolute, encoding: "UTF-8"),
      permitted_classes: [Date],
      aliases: true,
    ) || {}

    unless evidence["evidence_type"] == contract["evidence_type"]
      violations << "#{label}: invalid evidence_type"
    end
    contract.fetch("required_values", {}).each do |field, expected|
      violations << "#{label}: #{field} must be #{expected.inspect}" unless evidence[field] == expected
    end
    contract.fetch("field_patterns", {}).each do |field, pattern|
      unless evidence[field].to_s.match?(Regexp.new(pattern))
        violations << "#{label}: #{field} does not match #{pattern.inspect}"
      end
    end
    require_fields(evidence, Array(contract["required_fields"]), label)
    Array(contract["digest_fields"]).each do |field|
      unless evidence[field].to_s.match?(SHA256_PATTERN)
        violations << "#{label}: #{field} must be a lowercase SHA-256"
      end
    end

    digest_pairs = {
      "environment_contract_sha256" => @environment_path,
      "threat_model_sha256" => @threat_path,
      "artifact_sha256" => evidence["artifact_path"],
    }
    digest_pairs.each do |digest_field, target_relative|
      next unless evidence[digest_field]
      target = safe_repo_path(target_relative, label)
      next unless target
      unless File.file?(target)
        violations << "#{label}: referenced file is missing: #{target_relative}"
        next
      end
      actual = Digest::SHA256.file(target).hexdigest
      unless evidence[digest_field] == actual
        violations << "#{label}: #{digest_field} does not match #{target_relative}"
      end
    end
  rescue Psych::SyntaxError => error
    violations << "#{label}: invalid evidence YAML: #{error.message.lines.first.strip}"
  end

  def safe_repo_path(relative_path, label)
    if relative_path.to_s.empty?
      violations << "#{label}: evidence path is missing"
      return nil
    end
    unless relative_path.to_s.start_with?("docs/project/security/evidence/") ||
           [@environment_path, @threat_path].include?(relative_path.to_s)
      violations << "#{label}: evidence path must stay in docs/project/security/evidence"
      return nil
    end
    absolute = File.expand_path(relative_path.to_s, @repo_root)
    root_prefix = "#{@repo_root}#{File::SEPARATOR}"
    unless absolute.start_with?(root_prefix)
      violations << "#{label}: evidence path leaves repository"
      return nil
    end
    absolute
  end

  def relative(absolute)
    absolute.delete_prefix("#{@repo_root}#{File::SEPARATOR}")
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    profile: "development",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--profile PROFILE", BackendBoundaryValidator::PROFILES) do |value|
      options[:profile] = value
    end
  end.parse!

  validator = BackendBoundaryValidator.new(**options)
  if validator.run
    puts "Backend boundary gate PASS (#{options[:profile]})"
    exit 0
  end

  warn "Backend boundary gate FAIL (#{options[:profile]}):"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
