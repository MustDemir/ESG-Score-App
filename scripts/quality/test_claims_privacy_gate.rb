#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "optparse"
require "tmpdir"
require "yaml"

require_relative "validate_claims_privacy_boundaries"

class BoundaryGateSelfTest
  GATES = %w[claims privacy all].freeze

  def initialize(repo_root:, gate:)
    @repo_root = repo_root
    @gate = gate
    @assertions = 0
    @failures = []
  end

  def run
    test_claims if %w[claims all].include?(@gate)
    test_privacy if %w[privacy all].include?(@gate)

    if @failures.empty?
      puts "Claims/privacy gate self-tests PASS: #{@assertions} assertions"
      return true
    end

    warn "Claims/privacy gate self-tests FAIL:"
    @failures.each { |failure| warn "- #{failure}" }
    false
  end

  private

  def assert(condition, message)
    @assertions += 1
    @failures << message unless condition
  end

  def validator(root, gate, profile)
    ClaimsPrivacyBoundaryValidator.new(
      repo_root: root,
      gate: gate,
      profile: profile,
    )
  end

  def with_fixture
    Dir.mktmpdir("scanfair-boundary-gate-") do |root|
      %w[
        docs/project/compliance/source-register.yaml
        docs/project/compliance/claim-inventory.yaml
        docs/project/compliance/privacy-data-inventory.yaml
        docs/project/compliance/privacy-data-flow.md
        docs/project/compliance/compliance-manifest.json
        docs/project/gate-definitions/local/G-CLAIM-SAFETY.yaml
        docs/project/methodology-catalog/scoring-controls.yaml
        docs/project/methodology-catalog/parameters.yaml
        docs/project/decisions/0011-esg-score-formel.yaml
        docs/ESG-SCORING-MODELL-v1.md
        docs/privacy.md
        esg_app/lib/models/product.dart
        esg_app/lib/widgets/score_widgets.dart
        esg_app/lib/screens/scanner_screen.dart
        esg_app/lib/services/open_food_facts_service.dart
        esg_app/lib/services/product_repository.dart
        esg_app/ios/Runner/PrivacyInfo.xcprivacy
      ].each do |relative|
        destination = File.join(root, relative)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(File.join(@repo_root, relative), destination)
      end
      yield root
    end
  end

  def load_yaml(root, relative)
    YAML.safe_load(
      File.read(File.join(root, relative)),
      permitted_classes: [Date],
      aliases: true,
    )
  end

  def write_yaml(root, relative, data)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, YAML.dump(data))
  end

  def write(root, relative, content)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, content)
  end

  def digest(root, relative)
    Digest::SHA256.file(File.join(root, relative)).hexdigest
  end

  def test_claims
    with_fixture do |root|
      check = validator(root, "claims", "development")
      assert(check.run, "claims development fixture should pass: #{check.violations.join('; ')}")

      widget = File.join(root, "esg_app/lib/widgets/score_widgets.dart")
      File.open(widget, "a") { |file| file.puts("// gesund") }
      unsafe = validator(root, "claims", "development")
      assert(!unsafe.run, "claims gate should reject prohibited runtime wording")
      assert(
        unsafe.violations.any? { |entry| entry.include?("prohibited health") },
        "claims gate should explain prohibited wording",
      )
    end

    with_fixture do |root|
      pending = validator(root, "claims", "external_beta")
      assert(!pending.run, "claims external-beta profile should reject pending reviews")

      prepare_claim_approval(root)
      approved = validator(root, "claims", "external_beta")
      assert(approved.run, "claims external-beta fixture should pass with typed evidence: #{approved.violations.join('; ')}")

      File.open(File.join(root, "docs/project/compliance/review/claims-legal.md"), "a") do |file|
        file.puts("tampered")
      end
      tampered = validator(root, "claims", "external_beta")
      assert(!tampered.run, "claims gate should reject tampered review evidence")
      assert(
        tampered.violations.any? { |entry| entry.include?("does not match") },
        "claims gate should explain hash mismatch",
      )
    end
  end

  def prepare_claim_approval(root)
    inventory_path = "docs/project/compliance/claim-inventory.yaml"
    inventory = load_yaml(root, inventory_path)
    inventory["public_activation"]["enabled"] = true
    inventory["public_activation"]["claim_set_release_status"] = "approved"
    inventory["reviews"]["legal"]["status"] = "approved"
    inventory["reviews"]["legal"]["evidence"] = "docs/project/compliance/review/claims-legal-evidence.yaml"
    inventory["reviews"]["subject_matter"]["status"] = "approved"
    inventory["reviews"]["subject_matter"]["evidence"] = "docs/project/compliance/review/claims-domain-evidence.yaml"
    inventory["claims"].each do |claim|
      claim["release_status"] = "approved"
      if Array(claim["evidence_refs"]).empty?
        claim["evidence_refs"] = ["docs/project/compliance/review/website-snapshot.md"]
      end
    end

    write(root, "docs/project/compliance/review/website-snapshot.md", "Reviewed website snapshot\n")
    write(root, "docs/project/compliance/review/claims-legal.md", "Approved legal claim review\n")
    write(root, "docs/project/compliance/review/claims-domain.md", "Approved ESG and nutrition review\n")
    write_yaml(root, inventory_path, inventory)
    inventory_hash = digest(root, inventory_path)

    write_yaml(
      root,
      "docs/project/compliance/review/claims-legal-evidence.yaml",
      {
        "evidence_type" => "claims_legal_review",
        "decision" => "approved",
        "reviewer_role" => "qualified_consumer_and_food_claims_counsel",
        "schema_version" => "1.0",
        "reviewed_at" => "2026-08-11T12:00:00Z",
        "scope" => %w[app_runtime app_store website_marketing],
        "claim_inventory_sha256" => inventory_hash,
        "document_path" => "docs/project/compliance/review/claims-legal.md",
        "document_sha256" => digest(root, "docs/project/compliance/review/claims-legal.md"),
      },
    )
    write_yaml(
      root,
      "docs/project/compliance/review/claims-domain-evidence.yaml",
      {
        "evidence_type" => "claims_subject_matter_review",
        "decision" => "approved",
        "reviewer_roles" => %w[qualified_esg_lca_reviewer qualified_nutrition_reviewer],
        "schema_version" => "1.0",
        "reviewed_at" => "2026-08-11T12:00:00Z",
        "scope" => %w[app_runtime app_store website_marketing],
        "claim_inventory_sha256" => inventory_hash,
        "document_path" => "docs/project/compliance/review/claims-domain.md",
        "document_sha256" => digest(root, "docs/project/compliance/review/claims-domain.md"),
      },
    )
  end

  def test_privacy
    with_fixture do |root|
      check = validator(root, "privacy", "development")
      assert(check.run, "privacy development fixture should pass: #{check.violations.join('; ')}")

      inventory_path = "docs/project/compliance/privacy-data-inventory.yaml"
      inventory = load_yaml(root, inventory_path)
      inventory["current_feature_state"]["analytics_enabled"] = true
      write_yaml(root, inventory_path, inventory)
      mismatch = validator(root, "privacy", "development")
      assert(!mismatch.run, "privacy gate should reject undocumented feature activation")
      assert(
        mismatch.violations.any? { |entry| entry.include?("analytics_enabled") },
        "privacy gate should identify activated analytics",
      )
    end

    with_fixture do |root|
      pending = validator(root, "privacy", "external_beta")
      assert(!pending.run, "privacy external-beta profile should reject pending reviews")

      prepare_privacy_approval(root)
      approved = validator(root, "privacy", "external_beta")
      assert(approved.run, "privacy external-beta fixture should pass with typed evidence: #{approved.violations.join('; ')}")

      File.open(File.join(root, "docs/project/compliance/review/privacy-disclosure.md"), "a") do |file|
        file.puts("tampered")
      end
      tampered = validator(root, "privacy", "external_beta")
      assert(!tampered.run, "privacy gate should reject tampered review evidence")
      assert(
        tampered.violations.any? { |entry| entry.include?("does not match") },
        "privacy gate should explain hash mismatch",
      )

      remote = validator(root, "privacy", "remote_backend")
      assert(!remote.run, "remote profile should reject a repository-disabled backend")
    end
  end

  def prepare_privacy_approval(root)
    inventory_path = "docs/project/compliance/privacy-data-inventory.yaml"
    inventory = load_yaml(root, inventory_path)
    inventory["controller"]["postal_address_status"] = "complete"
    inventory["reviews"]["direct_lookup_roles_and_legal_basis"]["status"] = "approved"
    inventory["reviews"]["direct_lookup_roles_and_legal_basis"]["evidence"] = "docs/project/compliance/review/privacy-legal-evidence.yaml"
    inventory["reviews"]["public_privacy_disclosure"]["status"] = "approved"
    inventory["reviews"]["public_privacy_disclosure"]["evidence"] = "docs/project/compliance/review/privacy-disclosure-evidence.yaml"
    inventory["reviews"]["app_privacy_details"]["status"] = "completed"
    inventory["reviews"]["app_privacy_details"]["evidence"] = "docs/project/compliance/review/app-privacy-evidence.yaml"
    inventory["dpia"]["remote_or_beta_scope"]["decision_status"] = "approved"
    inventory["dpia"]["remote_or_beta_scope"]["evidence"] = "docs/project/compliance/review/dpia-evidence.yaml"

    privacy_path = File.join(root, "docs/privacy.md")
    privacy_text = File.read(privacy_path).gsub(/Entwurf|Stub/i, "Freigegeben")
    File.write(privacy_path, privacy_text)

    write(root, "docs/project/compliance/review/privacy-legal.md", "Approved direct-lookup legal review\n")
    write(root, "docs/project/compliance/review/privacy-disclosure.md", "Approved privacy disclosure\n")
    write(root, "docs/project/compliance/review/app-privacy-details.json", "{\"approved\":true}\n")
    write(root, "docs/project/compliance/review/dpia-screening.md", "Approved DPIA screening\n")
    write_yaml(root, inventory_path, inventory)
    inventory_hash = digest(root, inventory_path)

    base = {
      "schema_version" => "1.0",
      "reviewed_at" => "2026-08-11T12:00:00Z",
      "scope" => "external_beta",
      "privacy_inventory_sha256" => inventory_hash,
    }
    write_yaml(
      root,
      "docs/project/compliance/review/privacy-legal-evidence.yaml",
      base.merge(
        "evidence_type" => "privacy_legal_review",
        "decision" => "approved",
        "reviewer_role" => "qualified_data_protection_counsel",
        "document_path" => "docs/project/compliance/review/privacy-legal.md",
        "document_sha256" => digest(root, "docs/project/compliance/review/privacy-legal.md"),
      ),
    )
    write_yaml(
      root,
      "docs/project/compliance/review/privacy-disclosure-evidence.yaml",
      base.merge(
        "evidence_type" => "privacy_disclosure_review",
        "decision" => "approved",
        "reviewer_role" => "qualified_data_protection_counsel",
        "privacy_policy_url" => "https://example.test/privacy",
        "document_path" => "docs/project/compliance/review/privacy-disclosure.md",
        "document_sha256" => digest(root, "docs/project/compliance/review/privacy-disclosure.md"),
      ),
    )
    write_yaml(
      root,
      "docs/project/compliance/review/app-privacy-evidence.yaml",
      {
        "evidence_type" => "app_store_privacy_details",
        "status" => "completed",
        "schema_version" => "1.0",
        "recorded_at" => "2026-08-11T12:00:00Z",
        "recorded_by_role" => "release_owner",
        "scope" => "external_beta",
        "privacy_inventory_sha256" => inventory_hash,
        "artifact_path" => "docs/project/compliance/review/app-privacy-details.json",
        "artifact_sha256" => digest(root, "docs/project/compliance/review/app-privacy-details.json"),
      },
    )
    write_yaml(
      root,
      "docs/project/compliance/review/dpia-evidence.yaml",
      {
        "evidence_type" => "dpia_screening",
        "decision_status" => "approved",
        "schema_version" => "1.0",
        "assessed_at" => "2026-08-11T12:00:00Z",
        "assessed_by_role" => "qualified_data_protection_counsel",
        "scope" => "external_beta",
        "decision" => "dpia_not_required",
        "criteria" => %w[systematic_monitoring vulnerable_subjects innovative_technology],
        "privacy_inventory_sha256" => inventory_hash,
        "document_path" => "docs/project/compliance/review/dpia-screening.md",
        "document_sha256" => digest(root, "docs/project/compliance/review/dpia-screening.md"),
      },
    )
  end
end

options = {
  repo_root: File.expand_path("../..", __dir__),
  gate: "all",
}
OptionParser.new do |parser|
  parser.on("--gate GATE", BoundaryGateSelfTest::GATES) do |value|
    options[:gate] = value
  end
end.parse!

exit BoundaryGateSelfTest.new(**options).run ? 0 : 1
