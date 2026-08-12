#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "tmpdir"
require "yaml"

require_relative "validate_provider_governance"

class ProviderGovernanceSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    %w[dpa subprocessors cost].each do |gate|
      with_fixture do |root|
        check = validator(root, gate, "development")
        assert(check.run, "#{gate} development fixture should pass: #{check.violations.join('; ')}")
      end
    end

    with_fixture do |root|
      check = validator(root, "dpa", "remote_backend")
      assert(!check.run, "remote profile must reject pending DPA and disabled deployment")
      assert(includes?(check, "DPA owner approval"), "remote DPA failure should identify owner approval")
      assert(includes?(check, "typed provider approval evidence"), "remote DPA failure should require typed evidence")
    end

    with_fixture do |root|
      prepare_remote_approval(root)
      %w[remote_backend release_candidate].each do |profile|
        %w[dpa subprocessors cost].each do |gate|
          check = validator(root, gate, profile)
          assert(check.run, "#{gate} #{profile} fixture should pass: #{check.violations.join('; ')}")
        end
      end
    end

    with_fixture do |root|
      prepare_remote_approval(root)
      register_path = File.join(root, "docs/project/compliance/provider-governance-register.yaml")
      register = YAML.safe_load(File.read(register_path), permitted_classes: [Date], aliases: true)
      register["owner"] = "Tampered owner"
      File.write(register_path, YAML.dump(register))
      check = validator(root, "dpa", "remote_backend")
      assert(!check.run, "provider approval must reject a changed governance register")
      assert(includes?(check, "provider_register_sha256 does not match"), "tamper failure should identify the register digest")
    end

    with_fixture do |root|
      check = validator(root, "dpa", "development")
      result = check.send(:fetch_text, "http://example.com/provider-source")
      assert(result.nil?, "online source fetch must reject cleartext HTTP")
      assert(includes?(check, "must remain HTTPS"), "HTTP rejection should identify the transport boundary")
    end

    mutate_register(lambda do |register|
      register["reviews"]["dpa"]["next_periodic_review_at"] = Date.new(2026, 8, 11)
    end) do |root|
      check = validator(root, "dpa", "development")
      assert(!check.run, "DPA gate must reject an overdue review")
      assert(includes?(check, "periodic review is overdue"), "overdue failure should be explicit")
    end

    mutate_register(lambda do |register|
      register["personal_data_allowed"] = true
    end) do |root|
      check = validator(root, "dpa", "development")
      assert(!check.run, "development must reject personal-data activation")
      assert(includes?(check, "prohibit personal data"), "personal-data failure should be explicit")
    end

    mutate_register(lambda do |register|
      register["reviews"]["subprocessors"]["source_id"] = "UNKNOWN-SOURCE"
    end) do |root|
      check = validator(root, "subprocessors", "development")
      assert(!check.run, "subprocessor gate must reject an unknown source")
      assert(includes?(check, "unknown source"), "source failure should be explicit")
    end

    mutate_register(lambda do |register|
      register["reviews"]["cost_control"]["spend_cap"] = "enabled"
    end) do |root|
      check = validator(root, "cost", "development")
      assert(!check.run, "Free Plan must reject a fictitious Spend Cap")
      assert(includes?(check, "represented consistently"), "cost contradiction should be explicit")
    end

    mutate_register(lambda do |register|
      register["reviews"]["cost_control"]["thresholds_percent"]["egress"] = 90
    end) do |root|
      check = validator(root, "cost", "development")
      assert(!check.run, "cost gate must reject thresholds above seventy percent")
      assert(includes?(check, "egress threshold"), "threshold failure should identify the metric")
    end

    if @failures.empty?
      puts "Provider governance gate self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Provider governance gate self-tests FAIL:"
      @failures.each { |failure| warn "- #{failure}" }
      false
    end
  end

  private

  def assert(condition, message)
    @assertions += 1
    @failures << message unless condition
  end

  def includes?(check, text)
    check.violations.any? { |violation| violation.include?(text) }
  end

  def validator(root, gate, profile)
    ProviderGovernanceValidator.new(
      repo_root: root,
      gate: gate,
      profile: profile,
      today: Date.new(2026, 8, 12),
    )
  end

  def mutate_register(mutation)
    with_fixture do |root|
      path = File.join(root, "docs/project/compliance/provider-governance-register.yaml")
      register = YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
      mutation.call(register)
      File.write(path, YAML.dump(register))
      yield root
    end
  end

  def prepare_remote_approval(root)
    register_path = File.join(root, "docs/project/compliance/provider-governance-register.yaml")
    register = YAML.safe_load(File.read(register_path), permitted_classes: [Date], aliases: true)
    register["remote_schema_deployed"] = true
    register["remote_app_access_enabled"] = true
    register["reviews"]["dpa"]["decision"] = "approved"
    register["reviews"]["subprocessors"]["decision"] = "approved"
    register["reviews"]["subprocessors"]["change_notification_subscription"] = "confirmed"
    register["reviews"]["cost_control"]["plan_verification"] = "dashboard_evidence_reviewed"
    File.write(register_path, YAML.dump(register))

    environment_path = File.join(root, "docs/project/security/eu-supabase-environment-contract.yaml")
    environment = YAML.safe_load(File.read(environment_path), permitted_classes: [Date], aliases: true)
    environment["remote_backend_enabled"] = true
    environment["implementation_state"] = "deployed_to_eu_development"
    File.write(environment_path, YAML.dump(environment))

    artifact_relative = "docs/project/compliance/evidence/provider-governance-review.md"
    artifact_path = File.join(root, artifact_relative)
    FileUtils.mkdir_p(File.dirname(artifact_path))
    File.write(artifact_path, "Approved provider governance test evidence\n")

    evidence_relative = register.dig("provider_approval_evidence", "path")
    evidence_path = File.join(root, evidence_relative)
    FileUtils.mkdir_p(File.dirname(evidence_path))
    File.write(
      evidence_path,
      YAML.dump(
        {
          "schema_version" => "1.0",
          "evidence_type" => "provider_governance_approval",
          "decision" => "approved",
          "provider" => "Supabase",
          "project_name" => "scanfair-dev",
          "region" => "eu-central-1",
          "qualified_review_confirmed" => true,
          "reviewed_at" => "2026-08-12T12:00:00Z",
          "reviewed_commit_sha" => "a" * 40,
          "reviewer_identity" => "qualified-test-reviewer",
          "reviewer_roles" => %w[privacy_and_platform_owner privacy_and_vendor_owner product_and_platform_owner],
          "reviewer_qualifications" => {
            "privacy_and_platform_owner" => "test privacy qualification",
            "privacy_and_vendor_owner" => "test vendor qualification",
            "product_and_platform_owner" => "test cost qualification",
          },
          "approved_profiles" => %w[remote_backend release_candidate],
          "approved_gates" => %w[G-PROVIDER-DPA G-PROVIDER-SUBPROCESSORS G-COST-CONTROL],
          "source_versions" => {
            "SUPABASE-DPA" => "v1-2026-08-01",
            "SUPABASE-SUBPROCESSORS" => "2026-06-01",
            "SUPABASE-COST-CONTROL" => "current-web",
          },
          "provider_register_sha256" => Digest::SHA256.file(register_path).hexdigest,
          "artifact_path" => artifact_relative,
          "artifact_sha256" => Digest::SHA256.file(artifact_path).hexdigest,
        },
      ),
    )
  end

  def with_fixture
    Dir.mktmpdir("scanfair-provider-governance-") do |root|
      %w[
        docs/project/compliance/provider-governance-register.yaml
        docs/project/compliance/source-register.yaml
        docs/project/security/eu-supabase-environment-contract.yaml
      ].each { |relative| copy(root, relative) }
      yield root
    end
  end

  def copy(root, relative)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(File.join(@repo_root, relative), destination)
  end
end

root = File.expand_path("../..", __dir__)
exit(ProviderGovernanceSelfTest.new(repo_root: root).run ? 0 : 1)
