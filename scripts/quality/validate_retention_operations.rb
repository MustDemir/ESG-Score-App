#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "optparse"
require "time"
require "yaml"

class RetentionOperationsValidator
  PROFILES = %w[development remote_backend release_candidate].freeze
  CONTRACT_PATH = "docs/project/security/retention-observability-contract.yaml"
  ENVIRONMENT_PATH = "docs/project/security/eu-supabase-environment-contract.yaml"
  DELIVERY_EVIDENCE_PATH = "docs/project/security/evidence/retention-alert-delivery.yaml"
  MIGRATION_PATH = "supabase/migrations/20260820000100_retention_observability.sql"
  TEST_PATH = "supabase/tests/database/retention_observability.test.sql"
  AUDIT_PATH = "docs/project/audits/2026-08-20-retention-scheduled-run-observation.md"
  ADR_PATH = "docs/project/decisions/0038-retention-observability-and-alert-delivery.yaml"
  GATE_PATH = "docs/project/gate-definitions/local/G-RETENTION-OPS.yaml"

  attr_reader :violations, :report

  def initialize(repo_root:, profile: "development", report_dir: ".quality/retention-operations")
    @repo_root = File.expand_path(repo_root)
    @profile = profile
    @report_dir = report_dir
    @violations = []
  end

  def run
    unless PROFILES.include?(@profile)
      violations << "unknown profile #{@profile.inspect}"
      return finish
    end

    @contract = load_yaml(CONTRACT_PATH)
    @environment = load_yaml(ENVIRONMENT_PATH)
    validate_contract
    validate_repository_markers
    validate_strict_profile unless @profile == "development"
    finish
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

  def read(relative)
    File.read(path(relative), encoding: "UTF-8")
  rescue Errno::ENOENT
    violations << "#{relative}: file is missing"
    ""
  end

  def require_fields(object, fields, label)
    fields.each do |field|
      value = object[field]
      violations << "#{label}: missing #{field}" if value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end

  def expect(object, field, expected, label)
    return if object[field] == expected

    violations << "#{label}.#{field} must be #{expected.inspect}"
  end

  def validate_contract
    label = CONTRACT_PATH
    require_fields(
      @contract,
      %w[schema_version last_reviewed owner status implementation_state runtime_state purpose scheduled_cleanup_observation health_monitor detection_contract alert_outbox external_delivery profiles implementation_evidence remote_activation_blocks primary_sources],
      label,
    )
    return if @contract.empty?

    expect(@contract, "schema_version", "1.0", label)
    expect(@contract, "status", "accepted_for_local_implementation", label)
    expect(@contract, "implementation_state", "local_observability_validated_remote_pending", label) if @profile == "development"
    expect(@contract, "runtime_state", "disabled", label)
    validate_observation
    validate_monitor
    validate_detection
    validate_alerts
    validate_evidence
  end

  def validate_observation
    observation = @contract.fetch("scheduled_cleanup_observation", {})
    label = "#{CONTRACT_PATH}: scheduled_cleanup_observation"
    require_fields(observation, %w[environment region observed_at_utc evidence cleanup_runs_observed successful_runs_observed latest_run_started_at_utc latest_run_status eligible_backlog_rows runtime_rows], label)
    expect(observation, "environment", "scanfair-dev", label)
    expect(observation, "region", "eu-central-1", label)
    unless observation["cleanup_runs_observed"].to_i >= 2 &&
           observation["successful_runs_observed"].to_i >= 2 &&
           observation["latest_run_status"] == "succeeded" &&
           observation["eligible_backlog_rows"] == 0 &&
           observation["runtime_rows"] == 0
      violations << "#{label}: two successful runs and zero eligible/runtime rows are required"
    end
    expect(observation, "evidence", AUDIT_PATH, label)
  end

  def validate_monitor
    monitor = @contract.fetch("health_monitor", {})
    label = "#{CONTRACT_PATH}: health_monitor"
    expected = {
      "scheduler" => "pg_cron",
      "job_name" => "scanfair-retention-health-monitor",
      "schedule_utc" => "30 3 * * *",
      "command" => "select private.record_retention_health();",
      "execution_database" => "postgres",
      "execution_role" => "postgres",
      "maximum_cleanup_success_age_hours" => 36,
      "history_retention_days" => 90,
      "forbidden_roles" => %w[anon authenticated service_role],
    }
    expected.each { |field, value| expect(monitor, field, value, label) }
    expect(monitor.fetch("tables", {}), "health_history", "private.retention_health_checks", "#{label}.tables")
    expect(monitor.fetch("tables", {}), "alert_outbox", "private.retention_alert_outbox", "#{label}.tables")
    expect(monitor.fetch("functions", {}), "snapshot", "private.retention_health_snapshot(timestamptz)", "#{label}.functions")
    expect(monitor.fetch("functions", {}), "recorder", "private.record_retention_health(timestamptz)", "#{label}.functions")
  end

  def validate_detection
    detection = @contract.fetch("detection_contract", {})
    critical = %w[cleanup_job_configuration_invalid monitor_job_configuration_invalid cleanup_success_stale cleanup_latest_run_failed cleanup_backlog_persistent_seven_checks]
    warning = %w[cleanup_backlog_at_or_above_batch cleanup_duration_partition_review writer_audit_partition_review]
    expect(detection, "critical", critical, "#{CONTRACT_PATH}: detection_contract")
    expect(detection, "warning", warning, "#{CONTRACT_PATH}: detection_contract")
    expected_thresholds = {
      "cleanup_batch_rows" => 10_000,
      "persistent_backlog_checks" => 7,
      "slow_cleanup_seconds" => 2,
      "consecutive_slow_runs" => 3,
      "writer_audit_rows" => 1_000_000,
    }
    expect(detection, "thresholds", expected_thresholds, "#{CONTRACT_PATH}: detection_contract")
  end

  def validate_alerts
    outbox = @contract.fetch("alert_outbox", {})
    expected_outbox = {
      "one_open_alert_per_code" => true,
      "occurrence_counter" => "required",
      "recovery_resolution" => "automatic",
      "resolved_retention_days" => 400,
      "payload_contains_secrets" => "prohibited",
      "payload_contains_personal_data" => "prohibited",
    }
    expected_outbox.each { |field, value| expect(outbox, field, value, "#{CONTRACT_PATH}: alert_outbox") }

    delivery = @contract.fetch("external_delivery", {})
    expect(delivery, "state", "not_configured_runtime_disabled", "#{CONTRACT_PATH}: external_delivery") if @profile == "development"
    prohibited = %w[broad_long_lived_supabase_management_token_for_routine_monitoring paid_log_drain_without_cost_and_provider_approval mobile_or_service_role_access_to_operational_tables]
    required = %w[named_delivery_owner least_privilege_delivery_identity environment_scoped_secret_storage_and_rotation cost_and_subprocessor_review controlled_failure_notification_received recovery_notification_received delivery_failure_negative_test]
    expect(delivery, "prohibited_shortcuts", prohibited, "#{CONTRACT_PATH}: external_delivery")
    expect(delivery, "activation_requires", required, "#{CONTRACT_PATH}: external_delivery")
  end

  def validate_evidence
    evidence = @contract.fetch("implementation_evidence", {})
    expected = {
      "local_migrations" => "13/13 REPLAYED",
      "database_tests" => "250/250 PASS",
      "database_lint" => "PASS",
      "remote_verifier_local_dry_run" => "PASS_WITH_ROLLBACK",
      "remote_migration" => "NOT_APPLIED",
      "monitor_scheduled_runs_observed" => 0,
      "notification_drill" => "NOT_RUN",
    }
    expected.each { |field, value| expect(evidence, field, value, "#{CONTRACT_PATH}: implementation_evidence") } if @profile == "development"
    required_artifacts = [MIGRATION_PATH, TEST_PATH, ADR_PATH, AUDIT_PATH, "scripts/quality/validate_retention_operations.rb", "scripts/quality/test_retention_operations_gate.rb"]
    missing = required_artifacts - Array(evidence["artifacts"])
    violations << "#{CONTRACT_PATH}: implementation_evidence.artifacts missing #{missing.join(', ')}" unless missing.empty?
  end

  def validate_repository_markers
    checks = {
      MIGRATION_PATH => [
        "create table if not exists private.retention_health_checks",
        "create table if not exists private.retention_alert_outbox",
        "private.retention_health_snapshot",
        "private.record_retention_health",
        "scanfair-retention-health-monitor",
        "30 3 * * *",
        "revoke all on table private.retention_health_checks",
        "from public, anon, authenticated, service_role",
      ],
      TEST_PATH => ["plan(37)", "cleanup_latest_run_failed", "cleanup_backlog_persistent_seven_checks", "cron.unschedule"],
      AUDIT_PATH => ["2026-08-19 03:20:00.288", "2026-08-20 03:20:00.244", "zero"],
      ADR_PATH => ["not_configured_runtime_disabled", "SUPABASE-LOG-DRAINS", "G-RETENTION-OPS"],
      GATE_PATH => ["schema_profile: scanfair-gate-v1", "RETOPS-006", "waiver:", "allowed: false"],
    }
    checks.each do |relative, markers|
      content = read(relative)
      markers.each do |marker|
        violations << "#{relative}: missing marker #{marker.inspect}" unless content.downcase.include?(marker.downcase)
      end
    end
  end

  def validate_strict_profile
    expect(@contract, "implementation_state", "remote_observability_verified", CONTRACT_PATH)
    evidence = @contract.fetch("implementation_evidence", {})
    violations << "#{@profile}: retention observability migration must be remotely applied" unless evidence["remote_migration"] == "APPLIED_AND_VERIFIED"
    violations << "#{@profile}: at least one real scheduled monitor run is required" unless evidence["monitor_scheduled_runs_observed"].to_i >= 1
    delivery = @contract.fetch("external_delivery", {})
    violations << "#{@profile}: external alert delivery must be configured and tested" unless delivery["state"] == "configured_and_tested"
    violations << "#{@profile}: failure and recovery notification drill must pass" unless evidence["notification_drill"] == "PASS"
    validate_delivery_evidence
    if @profile == "release_candidate"
      violations << "release_candidate: independent operations review is required" unless @contract.dig("profiles", "release_candidate", "independent_operations_review_status") == "approved"
    end
  end

  def validate_delivery_evidence
    evidence = load_yaml(DELIVERY_EVIDENCE_PATH)
    return if evidence.empty?

    required = %w[schema_version reviewed_at reviewer_role environment delivery_owner delivery_channel least_privilege_identity secret_rotation_status cost_review_status subprocessor_review_status failure_notification_received recovery_notification_received delivery_failure_negative_test decision]
    require_fields(evidence, required, DELIVERY_EVIDENCE_PATH)
    expect(evidence, "environment", "scanfair-dev", DELIVERY_EVIDENCE_PATH)
    %w[failure_notification_received recovery_notification_received delivery_failure_negative_test].each do |field|
      expect(evidence, field, true, DELIVERY_EVIDENCE_PATH)
    end
    expect(evidence, "decision", "approved", DELIVERY_EVIDENCE_PATH)
  end

  def finish
    @report = {
      "gate_id" => "G-RETENTION-OPS",
      "profile" => @profile,
      "status" => violations.empty? ? "PASS" : "FAIL",
      "generated_at" => Time.now.utc.iso8601,
      "runtime_enabled" => @contract && @contract["runtime_state"] != "disabled",
      "external_delivery_state" => @contract&.dig("external_delivery", "state"),
      "violations" => violations,
    }
    output_dir = path(@report_dir)
    FileUtils.mkdir_p(output_dir)
    File.write(File.join(output_dir, "report.json"), JSON.pretty_generate(report) + "\n")
    violations.empty?
  end
end

if $PROGRAM_NAME == __FILE__
  options = { profile: ENV.fetch("RETENTION_OPERATIONS_PROFILE", "development") }
  OptionParser.new do |parser|
    parser.on("--profile PROFILE") { |value| options[:profile] = value }
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--report-dir PATH") { |value| options[:report_dir] = value }
  end.parse!

  validator = RetentionOperationsValidator.new(
    repo_root: options[:repo_root] || File.expand_path("../..", __dir__),
    profile: options[:profile],
    report_dir: options[:report_dir] || ".quality/retention-operations",
  )

  if validator.run
    puts "G-RETENTION-OPS PASS (#{options[:profile]})"
    exit 0
  end

  warn "G-RETENTION-OPS FAIL (#{options[:profile]}):"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
