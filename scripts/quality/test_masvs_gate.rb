#!/usr/bin/env ruby

require "minitest/autorun"
require_relative "validate_masvs_baseline"

class MasvsGateTest < Minitest::Test
  def setup
    @repo_root = File.expand_path("../..", __dir__)
    @baseline = MasvsGate.load_yaml(
      File.join(@repo_root, "docs/project/compliance/owasp-masvs-ios-baseline.yaml"),
    )
    @checklist = MasvsGate.load_yaml(
      File.join(@repo_root, "docs/project/compliance/owasp-masvs-ios-manual-checklist.yaml"),
    )
  end

  def test_repository_baseline_passes_development_profile
    validator = validate(@baseline, profile: "development", verify_repository: true)

    assert validator.success?, validator.violations.join("\n")
    assert_equal 24, validator.controls.length
    refute_empty validator.warnings
  end

  def test_missing_control_fails_closed
    baseline = deep_copy(@baseline)
    baseline["controls"].reject! { |control| control["id"] == "MASVS-PRIVACY-4" }

    validator = validate(baseline)

    refute validator.success?
    assert_includes validator.violations, "baseline: missing control MASVS-PRIVACY-4"
  end

  def test_non_applicable_control_requires_activation_trigger
    baseline = deep_copy(@baseline)
    control = baseline["controls"].find { |item| item["id"] == "MASVS-AUTH-1" }
    control.delete("activation_trigger")

    validator = validate(baseline)

    refute validator.success?
    assert_includes validator.violations, "MASVS-AUTH-1: non-applicable control requires activation_trigger"
  end

  def test_manual_mapping_must_be_reciprocal
    baseline = deep_copy(@baseline)
    control = baseline["controls"].find { |item| item["id"] == "MASVS-NETWORK-1" }
    control["manual_check_ids"] = ["MASVS-IOS-99"]

    validator = validate(baseline)

    refute validator.success?
    assert_includes validator.violations, "MASVS-NETWORK-1: unknown manual check MASVS-IOS-99"
  end

  def test_release_candidate_blocks_open_must_controls_and_manual_checks
    validator = validate(@baseline, profile: "release_candidate")

    refute validator.success?
    assert validator.violations.any? { |item| item.include?("MASVS-CODE-1: MUST control is open") }
    assert validator.violations.any? { |item| item.include?("manual check MASVS-IOS-02 is not passed") }
  end

  private

  def validate(baseline, profile: "development", verify_repository: false)
    MasvsGate::Validator.new(
      repo_root: @repo_root,
      baseline: baseline,
      checklist: deep_copy(@checklist),
      profile: profile,
      verify_repository: verify_repository,
    ).validate
  end

  def deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
end
