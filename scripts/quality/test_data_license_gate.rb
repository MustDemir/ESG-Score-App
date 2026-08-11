#!/usr/bin/env ruby

require "minitest/autorun"
require "date"
require "tmpdir"
require "yaml"
require_relative "validate_data_license_composition"

class DataLicenseCompositionValidatorTest < Minitest::Test
  def setup
    @repo_root = File.expand_path("../..", __dir__)
    @policy = YAML.safe_load(
      File.read(
        File.join(
          @repo_root,
          "docs/project/data/license-composition-policy.yaml",
        ),
      ),
      permitted_classes: [Date],
      aliases: false,
    )
  end

  def test_current_development_contract_passes
    assert_empty validator(profile: "development").violations
  end

  def test_wrong_off_contents_license_fails
    policy = copy_policy
    policy["source_contracts"]["open-food-facts"]["contents_license"] =
      "CC-BY-SA"

    assert_includes(
      validator(profile: "development", policy: policy).violations,
      'open-food-facts.contents_license must equal "DbCL-1.0"',
    )
  end

  def test_external_source_in_off_cache_fails
    policy = copy_policy
    policy["architecture_contract"]["off_cache"]["allowed_sources"] <<
      "agribalyse"

    assert_includes(
      validator(profile: "development", policy: policy).violations,
      "OFF cache allowed_sources must contain only open-food-facts",
    )
  end

  def test_remote_profile_blocks_current_design_only_state
    violations = validator(profile: "remote_backend").violations

    assert_includes violations, "remote_backend requires remote backend enabled"
    assert_includes(
      violations,
      "remote_backend requires valid repository-backed remote activation evidence",
    )
    assert_includes(
      violations,
      "remote_backend requires approved qualified legal review",
    )
    assert_includes(
      violations,
      "remote_backend requires implemented share-alike export",
    )
    assert_includes(
      violations,
      "remote_backend requires implemented correction and deletion",
    )
  end

  def test_approval_labels_with_invalid_evidence_files_fail_closed
    policy = copy_policy
    policy["architecture_contract"]["remote_backend"]["enabled"] = true
    policy["architecture_contract"]["remote_backend"]["activation_evidence"] =
      "docs/project/data/license-composition-policy.yaml"
    policy["legal_review"]["status"] = "approved"
    policy["legal_review"]["evidence"] =
      "docs/project/data/license-composition-policy.yaml"
    policy["architecture_contract"]["share_alike_export"]["status"] =
      "implemented"
    policy["architecture_contract"]["share_alike_export"]["implementation_evidence"] =
      "docs/project/data/license-composition-policy.yaml"
    policy["architecture_contract"]["correction_and_deletion"]["status"] =
      "implemented"
    policy["architecture_contract"]["correction_and_deletion"]["implementation_evidence"] =
      "docs/project/data/license-composition-policy.yaml"

    violations = validator(profile: "remote_backend", policy: policy).violations

    assert_includes(
      violations,
      "remote_backend requires valid repository-backed remote activation evidence",
    )
    assert_includes(
      violations,
      "remote_backend requires valid repository-backed legal-review evidence",
    )
    assert_includes(
      violations,
      "remote_backend requires valid repository-backed share-alike export evidence",
    )
    assert_includes(
      violations,
      "remote_backend requires valid repository-backed correction and deletion evidence",
    )
  end

  def test_complete_typed_evidence_can_unlock_remote_profile
    policy = copy_policy
    policy["architecture_contract"]["remote_backend"]["enabled"] = true
    policy["legal_review"]["status"] = "approved"
    policy["architecture_contract"]["share_alike_export"]["status"] =
      "implemented"
    policy["architecture_contract"]["correction_and_deletion"]["status"] =
      "implemented"

    Dir.mktmpdir("data-license-evidence-", @repo_root) do |directory|
      policy["architecture_contract"]["remote_backend"]["activation_evidence"] =
        write_evidence(directory, "activation.yaml", {
          "schema_version" => "1.0",
          "evidence_type" => "remote_backend_activation",
          "status" => "approved",
          "recorded_at" => "2026-08-11T10:00:00Z",
          "approved_by_role" => "technical_product_owner",
          "scope" => ["remote_backend"],
          "artifact_sha256" => "a" * 64,
        })
      policy["legal_review"]["evidence"] =
        write_evidence(directory, "legal-review.yaml", {
          "schema_version" => "1.0",
          "evidence_type" => "data_license_legal_review",
          "decision" => "approved",
          "reviewer_role" => "qualified_data_licensing_counsel",
          "reviewed_at" => "2026-08-11",
          "scope" => ["OFF composition"],
          "document_sha256" => "b" * 64,
        })
      policy["architecture_contract"]["share_alike_export"]["implementation_evidence"] =
        write_evidence(directory, "share-alike-export.yaml", {
          "schema_version" => "1.0",
          "evidence_type" => "share_alike_export_verification",
          "status" => "verified",
          "verified_at" => "2026-08-11T10:00:00Z",
          "verified_by_role" => "quality_engineer",
          "scope" => ["off-odbl"],
          "artifact_sha256" => "c" * 64,
        })
      policy["architecture_contract"]["correction_and_deletion"]["implementation_evidence"] =
        write_evidence(directory, "correction-deletion.yaml", {
          "schema_version" => "1.0",
          "evidence_type" => "correction_deletion_verification",
          "status" => "verified",
          "verified_at" => "2026-08-11T10:00:00Z",
          "verified_by_role" => "quality_engineer",
          "scope" => ["source withdrawal", "score invalidation"],
          "artifact_sha256" => "d" * 64,
        })

      assert_empty(
        validator(profile: "remote_backend", policy: policy).violations,
      )
    end
  end

  def test_unknown_profile_fails_closed
    assert_equal(
      ['Unknown data-license profile "production-now"'],
      validator(profile: "production-now").violations,
    )
  end

  def test_release_candidate_requires_image_rights_review
    violations = validator(profile: "release_candidate").violations

    assert_includes(
      violations,
      "release_candidate requires approved image reuse review",
    )
    assert_includes(
      violations,
      "release_candidate requires valid repository-backed image-review evidence",
    )
  end

  private

  def validator(profile:, policy: @policy)
    DataLicenseCompositionValidator.new(
      repo_root: @repo_root,
      profile: profile,
      policy: policy,
    )
  end

  def copy_policy
    Marshal.load(Marshal.dump(@policy))
  end

  def write_evidence(directory, filename, manifest)
    path = File.join(directory, filename)
    File.write(path, YAML.dump(manifest))
    path.delete_prefix("#{@repo_root}/")
  end
end
