#!/usr/bin/env ruby

require "date"
require "fileutils"
require "tmpdir"
require "yaml"

require_relative "validate_gate_definitions"

class GateDefinitionSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    with_fixture do |root|
      check = validator(root)
      assert(check.run, "repository fixture should pass: #{check.violations.join('; ')}")
    end

    mutate_gate("G-PROVIDER-DPA", ->(gate) { gate.delete("criteria") }) do |check|
      assert(!check.run, "canonical gate must reject missing criteria")
      assert(includes?(check, "canonical metadata missing criteria"), "failure should identify missing criteria")
    end

    mutate_gate("G-GATE-DEFINITION-QUALITY", lambda do |gate|
      gate["criteria"].first["verification"] = "HYBRID"
    end) do |check|
      assert(!check.run, "AUTO gate must reject a HYBRID criterion")
      assert(includes?(check, "AUTO gate cannot contain"), "failure should identify automation contradiction")
    end

    mutate_gate("G-PROVIDER-DPA", lambda do |gate|
      gate["sources"] << "UNKNOWN-PROVIDER-SOURCE"
    end) do |check|
      assert(!check.run, "canonical gate must reject an unknown source")
      assert(includes?(check, "unknown source"), "failure should identify the source")
    end

    mutate_gate("G-COST-CONTROL", lambda do |gate|
      gate["waiver"]["conditions"] = ["owner says yes"]
    end) do |check|
      assert(!check.run, "prohibited waiver must reject conditions")
      assert(includes?(check, "prohibited waiver"), "failure should identify waiver contradiction")
    end

    mutate_gate("G-PROVIDER-SUBPROCESSORS", lambda do |gate|
      artifact = gate["artifacts"].find { |item| item["type"] == "repository_input" }
      artifact["path"] = "docs/project/does-not-exist.yaml"
    end) do |check|
      assert(!check.run, "canonical gate must reject a missing repository artifact")
      assert(includes?(check, "repository input does not exist"), "failure should identify missing artifact")
    end

    if @failures.empty?
      puts "Gate definition self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Gate definition self-tests FAIL:"
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

  def validator(root)
    GateDefinitionValidator.new(repo_root: root)
  end

  def mutate_gate(id, mutation)
    with_fixture do |root|
      relative = "docs/project/gate-definitions/local/#{id}.yaml"
      path = File.join(root, relative)
      gate = YAML.safe_load(File.read(path), permitted_classes: [Date], aliases: true)
      mutation.call(gate)
      File.write(path, YAML.dump(gate))
      yield validator(root)
    end
  end

  def with_fixture
    Dir.mktmpdir("scanfair-gate-definitions-") do |root|
      %w[
        docs/project
        scripts
        supabase/migrations/20260820000100_retention_observability.sql
        supabase/tests/database/retention_observability.test.sql
        .github/workflows/quality-gates.yml
      ].each { |relative| copy(root, relative) }
      yield root
    end
  end

  def copy(root, relative)
    source = File.join(@repo_root, relative)
    destination = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp_r(source, destination)
  end
end

root = File.expand_path("../..", __dir__)
exit(GateDefinitionSelfTest.new(repo_root: root).run ? 0 : 1)
