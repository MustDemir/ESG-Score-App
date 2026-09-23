#!/usr/bin/env ruby

require "json"
require "tmpdir"

require_relative "observe_compliance_sources"

class ComplianceSourceObservationSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    Dir.mktmpdir("scanfair-source-observation-") do |directory|
      observer = ComplianceSourceObserver.new(
        repo_root: @repo_root,
        report_path: File.join(directory, "source-observation.json"),
        offline: true,
        now: Time.utc(2026, 9, 4, 12, 0, 0),
      )
      assert(observer.run, "offline observation should complete")
      report = JSON.parse(File.read(File.join(directory, "source-observation.json"), encoding: "UTF-8"))
      assert(report["mode"] == "offline", "offline mode must be explicit")
      assert(report["automatic_approval"] == false, "observation must not grant automatic approval")
      assert(report.dig("manual_change_assessment", "required") == true, "manual review must be required")
      assert(report.fetch("sources").length == 10, "all unique regulatory-horizon sources must be observed")
      assert(report.fetch("sources").all? { |source| source["observation_status"] == "offline_not_checked" }, "offline sources must not be treated as reachable")
      assert(report.fetch("sources").all? { |source| source["manual_review_required"] == true && source["automatic_approval"] == false }, "each source must retain manual review")
      assert(report.fetch("sources").all? { |source| source["change_signal"] == "observation_not_run" }, "offline sources must not claim a change decision")
    end

    Dir.mktmpdir("scanfair-source-baseline-") do |directory|
      baseline_path = File.join(directory, "baseline.yaml")
      File.write(baseline_path, <<~YAML)
        schema_version: "1.0"
        sources:
          - id: APPLE-ARG
            state_signature: unchanged-signature
      YAML
      observer = ComplianceSourceObserver.new(repo_root: @repo_root, baseline_path: baseline_path, offline: true)
      observer.instance_variable_set(:@baseline_sources, {"APPLE-ARG" => {"state_signature" => "unchanged-signature"}})
      captured_marker = { "status" => "captured", "sample_sha256" => "sample" }
      unchanged = observer.send(:comparison_for, "APPLE-ARG", "unchanged-signature", captured_marker)
      changed = observer.send(:comparison_for, "APPLE-ARG", "changed-signature", captured_marker)
      missing = observer.send(:comparison_for, "UNKNOWN", "signature", captured_marker)
      unavailable = observer.send(:comparison_for, "APPLE-ARG", "signature", { "status" => "unavailable" })
      assert(unchanged["change_signal"] == "unchanged" && unchanged["manual_review_required"] == false, "unchanged technical baseline must not create a review")
      assert(changed["change_signal"] == "change_detected" && changed["manual_review_required"] == true, "changed source marker must require review")
      assert(missing["change_signal"] == "baseline_missing" && missing["manual_review_required"] == true, "missing baseline must require review")
      assert(unavailable["change_signal"] == "content_marker_inconclusive" && unavailable["manual_review_required"] == true, "inconclusive marker must require review")
    end

    if @failures.empty?
      puts "Compliance source observation self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Compliance source observation self-tests FAIL:"
      @failures.each { |failure| warn "- #{failure}" }
      false
    end
  end

  private

  def assert(condition, message)
    @assertions += 1
    @failures << message unless condition
  end
end

root = File.expand_path("../..", __dir__)
exit(ComplianceSourceObservationSelfTest.new(repo_root: root).run ? 0 : 1)
