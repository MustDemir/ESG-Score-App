#!/usr/bin/env ruby

require "fileutils"
require "minitest/autorun"
require "tmpdir"
require_relative "validate_retention_operations"

class RetentionOperationsGateTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)

  def setup
    @tmp = Dir.mktmpdir("retention-operations-gate")
    required_files.each do |relative|
      destination = File.join(@tmp, relative)
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(File.join(REPO_ROOT, relative), destination)
    end
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def validate(profile = "development")
    validator = RetentionOperationsValidator.new(
      repo_root: @tmp,
      profile: profile,
      report_dir: ".quality/test-retention-operations",
    )
    [validator.run, validator]
  end

  def mutate(relative, from, to)
    path = File.join(@tmp, relative)
    content = File.read(path)
    raise "fixture marker missing: #{from}" unless content.include?(from)

    File.write(path, content.sub(from, to))
  end

  def required_files
    [
      RetentionOperationsValidator::CONTRACT_PATH,
      RetentionOperationsValidator::ENVIRONMENT_PATH,
      RetentionOperationsValidator::MIGRATION_PATH,
      RetentionOperationsValidator::TEST_PATH,
      RetentionOperationsValidator::AUDIT_PATH,
      RetentionOperationsValidator::ADR_PATH,
      RetentionOperationsValidator::GATE_PATH,
    ]
  end

  def test_development_baseline_passes
    result, validator = validate
    assert result, validator.violations.join("\n")
    assert_equal "PASS", validator.report["status"]
  end

  def test_enabled_runtime_fails
    mutate(RetentionOperationsValidator::CONTRACT_PATH, "runtime_state: disabled", "runtime_state: enabled")
    result, validator = validate
    refute result
    assert validator.violations.any? { |item| item.include?("runtime_state") }
  end

  def test_monitor_schedule_change_fails
    mutate(RetentionOperationsValidator::CONTRACT_PATH, 'schedule_utc: "30 3 * * *"', 'schedule_utc: "31 3 * * *"')
    result, validator = validate
    refute result
    assert validator.violations.any? { |item| item.include?("schedule_utc") }
  end

  def test_migration_tamper_fails
    mutate(
      RetentionOperationsValidator::MIGRATION_PATH,
      "create table if not exists private.retention_health_checks",
      "create table if not exists private.changed_health_checks",
    )
    result, validator = validate
    refute result
    assert validator.violations.any? { |item| item.include?("missing marker") }
  end

  def test_false_successful_observation_fails
    mutate(RetentionOperationsValidator::CONTRACT_PATH, "successful_runs_observed: 2", "successful_runs_observed: 1")
    result, validator = validate
    refute result
    assert validator.violations.any? { |item| item.include?("two successful runs") }
  end

  def test_external_delivery_shortcut_change_fails
    mutate(RetentionOperationsValidator::CONTRACT_PATH, "paid_log_drain_without_cost_and_provider_approval", "paid_log_drain_allowed")
    result, validator = validate
    refute result
    assert validator.violations.any? { |item| item.include?("prohibited_shortcuts") }
  end

  def test_remote_profile_is_fail_closed
    result, validator = validate("remote_backend")
    refute result
    assert validator.violations.any? { |item| item.include?("migration must be remotely applied") }
    assert validator.violations.any? { |item| item.include?("scheduled monitor run") }
    assert validator.violations.any? { |item| item.include?("external alert delivery") }
    assert validator.violations.any? { |item| item.include?("notification drill") }
  end

  def test_release_profile_also_requires_independent_review
    result, validator = validate("release_candidate")
    refute result
    assert validator.violations.any? { |item| item.include?("independent operations review") }
  end

  def test_unknown_profile_fails
    result, validator = validate("production")
    refute result
    assert_includes validator.violations, 'unknown profile "production"'
  end
end
