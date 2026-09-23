#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "tmpdir"
require "yaml"

require_relative "validate_capability_declarations"

class CapabilityDeclarationSelfTest
  def initialize(repo_root:)
    @repo_root = repo_root
    @assertions = 0
    @failures = []
  end

  def run
    with_fixture do |root|
      assert(validator(root).run, "baseline fixture should pass")
    end

    with_fixture do |root|
      contract = contract_data(root)
      contract.fetch("rules").pop
      write_contract(root, contract)
      check = validator(root)
      assert(!check.run, "missing manifest declaration must fail")
      assert(includes?(check, "flags must exactly match"), "missing declaration failure must be named")
    end

    with_fixture do |root|
      File.write(File.join(root, "esg_app/lib/ai_client.dart"), "const endpoint = 'https://api.openai.com/v1';\n")
      check = validator(root)
      assert(!check.run, "undeclared AI provider must fail")
      assert(includes?(check, "feature_ai_system_enabled is false but forbidden indicator"), "AI false-negative must be named")
    end

    with_fixture do |root|
      manifest = manifest_data(root)
      manifest["feature_public_environmental_comparison_enabled"] = false
      write_manifest(root, manifest)
      check = validator(root)
      assert(check.run, "disabled public comparison does not require its presence marker")

      manifest["feature_public_environmental_comparison_enabled"] = true
      write_manifest(root, manifest)
      contract = contract_data(root)
      rule = contract.fetch("rules").find { |item| item["flag"] == "feature_public_environmental_comparison_enabled" }
      rule["required_indicators"][0]["pattern"] = "missing-runtime-marker"
      write_contract(root, contract)
      check = validator(root)
      assert(!check.run, "enabled public comparison without runtime marker must fail")
      assert(includes?(check, "required indicator aggregate_esg_score is absent"), "missing presence marker must be named")
    end

    with_fixture do |root|
      contract = contract_data(root)
      rule = contract.fetch("rules").find { |item| item["flag"] == "feature_eudr_operator_or_trader_enabled" }
      rule["evidence"] = "docs/missing-attestation.md"
      write_contract(root, contract)
      check = validator(root)
      assert(!check.run, "manual business-role attestation without evidence must fail")
      assert(includes?(check, "manual attestation needs repository evidence"), "manual evidence failure must be named")
    end

    if @failures.empty?
      puts "Capability declaration self-tests PASS: #{@assertions} assertions"
      true
    else
      warn "Capability declaration self-tests FAIL:"
      @failures.each { |failure| warn "- #{failure}" }
      false
    end
  end

  private

  def with_fixture
    Dir.mktmpdir("scanfair-capability-declarations-") do |root|
      FileUtils.cp_r(File.join(@repo_root, "docs"), root)
      FileUtils.mkdir_p(File.join(root, "esg_app"))
      FileUtils.cp_r(File.join(@repo_root, "esg_app", "."), File.join(root, "esg_app"))
      yield root
    end
  end

  def contract_data(root)
    YAML.safe_load(File.read(File.join(root, "docs/project/compliance/capability-declaration-contract.yaml")), permitted_classes: [Date], aliases: true)
  end

  def manifest_data(root)
    JSON.parse(File.read(File.join(root, "docs/project/compliance/compliance-manifest.json"), encoding: "UTF-8"))
  end

  def write_contract(root, data)
    File.write(File.join(root, "docs/project/compliance/capability-declaration-contract.yaml"), YAML.dump(data))
  end

  def write_manifest(root, data)
    File.write(File.join(root, "docs/project/compliance/compliance-manifest.json"), JSON.pretty_generate(data))
  end

  def validator(root)
    CapabilityDeclarationValidator.new(repo_root: root, report_path: ".quality/capability-declarations-test.json")
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
exit(CapabilityDeclarationSelfTest.new(repo_root: root).run ? 0 : 1)
