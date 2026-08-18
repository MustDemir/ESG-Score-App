#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "tmpdir"
require "yaml"

require_relative "validate_backend_boundary"

class BackendBoundaryGateSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    with_fixture do |root|
      check = validator(root, "development")
      assert(check.run, "development fixture should pass: #{check.violations.join('; ')}")
    end

    with_fixture do |root|
      contract_path = "docs/project/security/eu-supabase-environment-contract.yaml"
      contract = load_yaml(root, contract_path)
      contract["remote_backend_enabled"] = true
      write_yaml(root, contract_path, contract)
      check = validator(root, "development")
      assert(!check.run, "development must reject remote activation")
      assert(
        check.violations.any? { |entry| entry.include?("deployed schema must remain runtime-disabled") },
        "development failure should identify remote activation",
      )
    end

    with_fixture do |root|
      model_path = "docs/project/security/backend-threat-model.yaml"
      model = load_yaml(root, model_path)
      model["threats"].first["verification"] = []
      write_yaml(root, model_path, model)
      check = validator(root, "development")
      assert(!check.run, "gate must reject threats without verification")
      assert(
        check.violations.any? { |entry| entry.include?("THR-001: verification") },
        "threat failure should identify missing verification",
      )
    end

    with_fixture do |root|
      FileUtils.rm(
        File.join(root, "supabase/functions/_shared/writer_contract.mjs"),
      )
      check = validator(root, "development")
      assert(!check.run, "gate must reject a missing writer contract implementation")
      assert(
        check.violations.any? do |entry|
          entry.include?("writer_contract.mjs: file is missing")
        end,
        "implementation failure should identify the missing writer contract",
      )
    end

    with_fixture do |root|
      contract_path = "docs/project/security/eu-supabase-environment-contract.yaml"
      contract = load_yaml(root, contract_path)
      contract["key_and_identity_contract"]["mobile_application"]["allowed_key_types"] =
        %w[publishable secret]
      write_yaml(root, contract_path, contract)
      check = validator(root, "development")
      assert(!check.run, "gate must reject privileged mobile key types")
      assert(
        check.violations.any? { |entry| entry.include?("publishable keys only") },
        "key failure should identify the mobile boundary",
      )
    end

    with_fixture do |root|
      blocked = validator(root, "remote_backend")
      assert(!blocked.run, "remote profile must reject a contract-only environment")
    end

    with_fixture do |root|
      blocked = validator(root, "release_candidate")
      assert(!blocked.run, "release candidate must require its security review")
      assert(
        blocked.violations.any? { |entry| entry.include?("release_security review must be approved") },
        "release candidate failure should identify its missing security review",
      )
    end

    with_fixture do |root|
      prepare_release_review(root)
      approved = validator(root, "release_candidate")
      assert(
        approved.run,
        "disabled remote path should pass only with release review: #{approved.violations.join('; ')}",
      )
    end

    with_fixture do |root|
      prepare_remote_activation(root)
      approved = validator(root, "remote_backend")
      assert(
        approved.run,
        "remote profile should be satisfiable with typed evidence: #{approved.violations.join('; ')}",
      )

      File.open(
        File.join(root, "docs/project/security/evidence/writer-security-review.md"),
        "a",
      ) { |file| file.puts("tampered") }
      tampered = validator(root, "remote_backend")
      assert(!tampered.run, "remote profile must reject tampered evidence")
      assert(
        tampered.violations.any? { |entry| entry.include?("artifact_sha256 does not match") },
        "tampering failure should identify the artifact digest",
      )
    end

    if @failures.empty?
      puts "Backend boundary gate self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Backend boundary gate self-tests FAIL:"
      @failures.each { |failure| warn "- #{failure}" }
      false
    end
  end

  private

  def assert(condition, message)
    @assertions += 1
    @failures << message unless condition
  end

  def validator(root, profile)
    BackendBoundaryValidator.new(repo_root: root, profile: profile)
  end

  def with_fixture
    Dir.mktmpdir("scanfair-backend-boundary-") do |root|
      copy(root, "docs/project/security")
      copy(root, "docs/project/compliance/source-register.yaml")
      copy(root, "docs/project/decisions/0032-backend-security-boundary.yaml")
      copy(root, "esg_app/lib")
      copy(root, "esg_app/test/services/supabase_product_cache_service_test.dart")
      copy(root, "supabase/migrations")
      copy(root, "supabase/functions")
      copy(root, "supabase/tests/database")
      copy(root, "scripts/quality/run_edge_writer_integration_gate.sh")
      copy(root, "scripts/quality/verify_remote_backend_readiness.sql")
      copy(root, ".github/workflows/quality-gates.yml")
      yield root
    end
  end

  def copy(root, relative)
    source = File.join(@repo_root, relative)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp_r(source, destination)
  end

  def load_yaml(root, relative)
    YAML.safe_load(
      File.read(File.join(root, relative)),
      permitted_classes: [Date],
      aliases: true,
    )
  end

  def write_yaml(root, relative, content)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, YAML.dump(content))
  end

  def write(root, relative, content)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, content)
  end

  def digest(root, relative)
    Digest::SHA256.file(File.join(root, relative)).hexdigest
  end

  def prepare_remote_activation(root)
    contract_path = "docs/project/security/eu-supabase-environment-contract.yaml"
    model_path = "docs/project/security/backend-threat-model.yaml"
    contract = load_yaml(root, contract_path)
    contract["remote_backend_enabled"] = true
    contract["implementation_state"] = "deployed_to_eu_development"
    development = contract["environments"].find do |environment|
      environment["id"] == "development"
    end
    development["status"] = "active"
    development["dpa_status"] = "approved"

    evidence_paths = {
      "environment_activation" => "docs/project/security/evidence/environment-activation-evidence.yaml",
      "writer_security" => "docs/project/security/evidence/writer-security-evidence.yaml",
      "operational_readiness" => "docs/project/security/evidence/operational-readiness-evidence.yaml",
    }
    evidence_paths.each do |name, evidence_path|
      contract["reviews"][name]["status"] = "approved"
      contract["reviews"][name]["evidence"] = evidence_path
    end
    write_yaml(root, contract_path, contract)

    artifacts = {
      "environment_activation" => "environment-activation-review.md",
      "writer_security" => "writer-security-review.md",
      "operational_readiness" => "operational-readiness-review.md",
    }
    artifacts.each_value do |filename|
      write(
        root,
        "docs/project/security/evidence/#{filename}",
        "Approved test evidence for #{filename}\n",
      )
    end

    contract_hash = digest(root, contract_path)
    model_hash = digest(root, model_path)
    base = {
      "schema_version" => "1.0",
      "reviewed_at" => "2026-08-11T14:00:00Z",
      "environment_contract_sha256" => contract_hash,
      "threat_model_sha256" => model_hash,
      "decision" => "approved",
    }

    write_yaml(
      root,
      evidence_paths["environment_activation"],
      base.merge(
        "evidence_type" => "backend_environment_activation",
        "environment" => "development",
        "region" => "eu-central-1",
        "dpa_status" => "approved",
        "reviewer_role" => "privacy_and_platform_owner",
        "artifact_path" => "docs/project/security/evidence/#{artifacts['environment_activation']}",
        "artifact_sha256" => digest(
          root,
          "docs/project/security/evidence/#{artifacts['environment_activation']}",
        ),
      ),
    )
    %w[writer_security operational_readiness].each do |name|
      evidence_type = name == "writer_security" ?
        "backend_writer_security_review" : "backend_operational_readiness"
      write_yaml(
        root,
        evidence_paths[name],
        base.merge(
          "evidence_type" => evidence_type,
          "reviewer_role" => name == "writer_security" ?
            "independent_security_reviewer" : "operations_owner",
          "tested_controls" => %w[authentication authorization idempotency audit recovery],
          "artifact_path" => "docs/project/security/evidence/#{artifacts[name]}",
          "artifact_sha256" => digest(
            root,
            "docs/project/security/evidence/#{artifacts[name]}",
          ),
        ),
      )
    end
  end

  def prepare_release_review(root)
    contract_path = "docs/project/security/eu-supabase-environment-contract.yaml"
    model_path = "docs/project/security/backend-threat-model.yaml"
    evidence_path = "docs/project/security/evidence/release-security-evidence.yaml"
    artifact_path = "docs/project/security/evidence/release-security-review.md"
    contract = load_yaml(root, contract_path)
    contract["reviews"]["release_security"]["status"] = "approved"
    contract["reviews"]["release_security"]["evidence"] = evidence_path
    write_yaml(root, contract_path, contract)
    write(root, artifact_path, "Approved release security review evidence\n")
    write_yaml(
      root,
      evidence_path,
      {
        "schema_version" => "1.0",
        "evidence_type" => "backend_release_security_review",
        "reviewed_at" => "2026-08-12T11:00:00Z",
        "reviewer_role" => "independent_security_reviewer",
        "reviewed_commit_sha" => "a" * 40,
        "tested_controls" => %w[authentication authorization secrets ssrf rate_limits idempotency audit incident_response],
        "decision" => "approved",
        "profile" => "release_candidate",
        "environment_contract_sha256" => digest(root, contract_path),
        "threat_model_sha256" => digest(root, model_path),
        "artifact_path" => artifact_path,
        "artifact_sha256" => digest(root, artifact_path),
      },
    )
  end
end

repo_root = File.expand_path("../..", __dir__)
exit BackendBoundaryGateSelfTest.new(repo_root: repo_root).run ? 0 : 1
