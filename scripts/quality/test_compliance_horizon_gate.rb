#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "tmpdir"
require "yaml"

require_relative "validate_compliance_horizon"

class ComplianceHorizonSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    runner = File.read(File.join(@repo_root, "scripts/quality/run_quality_gates.sh"), encoding: "UTF-8")
    runner_body = runner[/^gate_compliance_horizon\(\) \{.*?^\}/m].to_s
    assert(runner_body.include?("! ruby scripts/quality/test_compliance_horizon_gate.rb"), "runner must make the horizon self-test mandatory")
    assert(runner_body.include?("! ruby scripts/quality/test_compliance_source_observation.rb"), "runner must make the source-observation self-test mandatory")
    assert(runner_body.index("return 1").to_i < runner_body.index('if [ "$profile" = "development" ]').to_i, "runner must return before profile validation after a failed self-test")

    with_fixture do |root|
      assert(validator(root, gate: "horizon").run, "baseline horizon fixture should pass")
      assert(validator(root, gate: "regulatory_applicability").run, "baseline applicability fixture should pass")
      assert(validator(root, gate: "uwg_comparison_transparency").run, "baseline UWG fixture should pass")
    end

    mutate_control("HZN-EU-GREEN-TRANSITION", ->(control) { control["source_refs"] = ["UNKNOWN-SOURCE"] }) do |check|
      assert(!check.run, "unknown source must fail")
      assert(includes?(check, "unknown source"), "unknown source must be named")
    end

    mutate_control("HZN-EU-AI-ACT-ART50", ->(control) { control.dig("applicability", "flags") << "missing_flag" }) do |check|
      assert(!check.run, "missing manifest flag must fail")
      assert(includes?(check, "manifest flag missing_flag is missing"), "missing flag must be named")
    end

    mutate_control("HZN-APPLE-AGE-ASSURANCE", ->(control) { control.dig("manual_change_assessment")["automatic_approval"] = true }) do |check|
      assert(!check.run, "automatic legal approval must fail")
      assert(includes?(check, "must prohibit automatic approval"), "automatic-approval failure must be named")
    end

    with_fixture do |root|
      baseline_path = File.join(root, "docs/project/compliance/source-observation-baseline.yaml")
      baseline = YAML.safe_load(File.read(baseline_path), permitted_classes: [Date], aliases: true)
      baseline["automatic_approval"] = "allowed"
      File.write(baseline_path, YAML.dump(baseline))
      check = validator(root, gate: "horizon")
      assert(!check.run, "source-observation baseline must prohibit automatic approval")
      assert(includes?(check, "source-observation-baseline.yaml: automatic approval must be prohibited"), "baseline automatic-approval failure must be named")
    end

    with_fixture do |root|
      report_path = write_source_observation_report(root)
      check = validator(root, gate: "horizon", profile: "release_candidate", source_observation_report_path: report_path)
      assert(!check.run, "strict profile must reject an unreviewed source signal")
      assert(includes?(check, "APPLE-ARG: source observation change_detected lacks a matching manual review record"), "unreviewed source signal must be named")
    end

    with_fixture do |root|
      report_path = write_source_observation_report(root)
      review_log_path = File.join(root, "docs/project/compliance/source-observation-review-log.yaml")
      review_log = YAML.safe_load(File.read(review_log_path), permitted_classes: [Date], aliases: true)
      review_log["entries"] << {
        "source_id" => "APPLE-ARG",
        "observed_state_signature" => "a" * 64,
        "observation_generated_at" => "2026-09-04T12:00:00Z",
        "assessment" => "completed",
        "reviewed_at" => "2026-09-04T12:00:01Z",
        "reviewer_role" => "Compliance and release owner",
        "evidence" => "docs/project/compliance/apple-review-relevance.md",
        "automatic_approval" => false,
      }
      File.write(review_log_path, YAML.dump(review_log))
      check = validator(root, gate: "horizon", profile: "release_candidate", source_observation_report_path: report_path)
      assert(check.run, "strict profile accepts a later matching manual source review")

      rerun_report = JSON.parse(File.read(File.join(root, report_path), encoding: "UTF-8"))
      rerun_report["generated_at"] = "2026-09-05T12:00:00Z"
      File.write(File.join(root, report_path), JSON.pretty_generate(rerun_report))
      rerun_check = validator(root, gate: "horizon", profile: "release_candidate", source_observation_report_path: report_path)
      assert(rerun_check.run, "a fresh run must accept the already reviewed matching source state")
    end

    with_fixture do |root|
      report_path = write_source_observation_report(root)
      review_log_path = File.join(root, "docs/project/compliance/source-observation-review-log.yaml")
      review_log = YAML.safe_load(File.read(review_log_path), permitted_classes: [Date], aliases: true)
      review_log["entries"] << {
        "source_id" => "APPLE-ARG",
        "observed_state_signature" => "a" * 64,
        "observation_generated_at" => "2026-09-04T12:00:02Z",
        "assessment" => "completed",
        "reviewed_at" => "2026-09-04T12:00:01Z",
        "reviewer_role" => "Compliance and release owner",
        "evidence" => "docs/project/compliance/apple-review-relevance.md",
        "automatic_approval" => false,
      }
      File.write(review_log_path, YAML.dump(review_log))
      check = validator(root, gate: "horizon", profile: "release_candidate", source_observation_report_path: report_path)
      assert(!check.run, "manual review must not predate its recorded source observation")
      assert(includes?(check, "manual review predates the observed source state"), "review chronology failure must be named")
    end

    mutate_control("HZN-EU-GREEN-TRANSITION", ->(control) { control.dig("comparison_contract")["methodology_path"] = "docs/missing.md" }) do |check|
      check = validator(check.repo_root, gate: "uwg_comparison_transparency")
      assert(!check.run, "missing comparison methodology must fail")
      assert(includes?(check, "methodology_path does not exist"), "missing methodology must be named")
    end

    with_fixture do |root|
      horizon = horizon_data(root)
      control = horizon.fetch("controls").find { |item| item["id"] == "HZN-EU-GREEN-TRANSITION" }
      control["release_evidence_status"] = "not_due"
      control.dig("comparison_contract")["legal_review_status"] = "pending_qualified_review"
      write_horizon(root, horizon)
      check = validator(root, gate: "uwg_comparison_transparency", profile: "release_candidate", today: Date.new(2026, 9, 27))
      assert(!check.run, "due sustainability comparison without legal review must fail release candidate")
      assert(includes?(check, "qualified legal review is required"), "due legal review failure must be named")
    end

    mutate_control("HZN-EU-AI-ACT-ART50", ->(control) { control["next_review_due"] = "2026-09-03" }) do |check|
      check = validator(check.repo_root, gate: "regulatory_applicability", profile: "release_candidate")
      assert(!check.run, "overdue control review must fail release candidate")
      assert(includes?(check, "control review overdue since 2026-09-03"), "overdue control review must be named")
    end

    with_fixture do |root|
      horizon = horizon_data(root)
      horizon["next_full_review_due"] = "2026-09-03"
      write_horizon(root, horizon)
      check = validator(root, gate: "horizon", profile: "development")
      assert(check.run, "overdue full review is a development warning, not a development block")
      assert(check.warnings.any? { |warning| warning.include?("full review overdue since 2026-09-03") }, "development warning must name the overdue full review")
    end

    with_fixture do |root|
      horizon = horizon_data(root)
      control = horizon.fetch("controls").find { |item| item["id"] == "HZN-EU-GREEN-TRANSITION" }
      control.dig("comparison_contract")["legal_review_due"] = "2026-09-03"
      control.dig("comparison_contract")["legal_review_status"] = "pending_qualified_review"
      write_horizon(root, horizon)
      check = validator(root, gate: "uwg_comparison_transparency", profile: "release_candidate")
      assert(!check.run, "overdue qualified legal review must fail before the effective date")
      assert(includes?(check, "qualified legal review overdue since 2026-09-03"), "overdue qualified legal review must be named")
    end

    if @failures.empty?
      puts "Compliance horizon self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Compliance horizon self-tests FAIL:"
      @failures.each { |failure| warn "- #{failure}" }
      false
    end
  end

  private

  def with_fixture
    Dir.mktmpdir("scanfair-compliance-horizon-") do |root|
      FileUtils.cp_r(File.join(@repo_root, "docs"), root)
      yield root
    end
  end

  def horizon_data(root)
    YAML.safe_load(File.read(File.join(root, "docs/project/compliance/regulatory-horizon.yaml")), permitted_classes: [Date], aliases: true)
  end

  def write_horizon(root, data)
    File.write(File.join(root, "docs/project/compliance/regulatory-horizon.yaml"), YAML.dump(data))
  end

  def mutate_control(id, mutation)
    with_fixture do |root|
      horizon = horizon_data(root)
      control = horizon.fetch("controls").find { |item| item["id"] == id }
      mutation.call(control)
      write_horizon(root, horizon)
      yield validator(root)
    end
  end

  def write_source_observation_report(root)
    relative_path = ".quality/compliance-horizon/test-source-observation.json"
    path = File.join(root, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, JSON.pretty_generate({
      "generated_at" => "2026-09-04T12:00:00Z",
      "automatic_approval" => false,
      "sources" => [{
        "id" => "APPLE-ARG",
        "state_signature" => "a" * 64,
        "change_signal" => "change_detected",
        "manual_review_required" => true,
      }],
    }))
    relative_path
  end

  def validator(root, gate: "horizon", profile: "development", source_observation_report_path: nil, today: Date.new(2026, 9, 4))
    ComplianceHorizonValidator.new(repo_root: root, gate: gate, profile: profile, report_path: ".quality/test-report.json", source_observation_report_path: source_observation_report_path, today: today)
  end

  def assert(condition, message)
    @assertions += 1
    @failures << message unless condition
  end

  def includes?(check, text)
    check.violations.any? { |violation| violation.include?(text) }
  end
end

root = File.expand_path("../..", __dir__)
exit(ComplianceHorizonSelfTest.new(repo_root: root).run ? 0 : 1)
