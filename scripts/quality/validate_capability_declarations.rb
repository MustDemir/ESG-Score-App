#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "optparse"
require "set"
require "time"
require "yaml"

class CapabilityDeclarationValidator
  VALID_MODES = %w[static_absence static_presence manual_attestation].freeze
  TEXT_EXTENSIONS = %w[.dart .yaml .yml .json .plist .xml].freeze

  attr_reader :violations, :report

  def initialize(repo_root:, report_path: ".quality/compliance-horizon/capability-declarations.json")
    @repo_root = File.expand_path(repo_root)
    @report_path = report_path
    @violations = []
  end

  def run
    manifest = load_json("docs/project/compliance/compliance-manifest.json")
    contract = load_yaml("docs/project/compliance/capability-declaration-contract.yaml")
    validate_contract(contract, manifest)
    build_report(manifest, contract)
    write_report
    violations.empty?
  end

  private

  def absolute(path)
    File.absolute_path(path, @repo_root)
  end

  def load_json(path)
    JSON.parse(File.read(absolute(path), encoding: "UTF-8"))
  rescue Errno::ENOENT
    violation("#{path}: file is missing")
    {}
  rescue JSON::ParserError => error
    violation("#{path}: invalid JSON: #{error.message}")
    {}
  end

  def load_yaml(path)
    YAML.safe_load(File.read(absolute(path), encoding: "UTF-8"), permitted_classes: [Date, Time], aliases: true) || {}
  rescue Errno::ENOENT
    violation("#{path}: file is missing")
    {}
  rescue Psych::SyntaxError => error
    violation("#{path}: invalid YAML: #{error.message.lines.first.strip}")
    {}
  end

  def validate_contract(contract, manifest)
    violation("capability declaration contract schema_version must be 1.0") unless contract["schema_version"] == "1.0"
    %w[owner scope rules].each { |field| violation("capability declaration contract: missing #{field}") if blank?(contract[field]) }

    flags = manifest.keys.grep(/\Afeature_/).sort
    flags.each { |flag| violation("manifest flag #{flag} must be boolean") unless [true, false].include?(manifest[flag]) }
    rules = Array(contract["rules"])
    rule_ids = rules.map { |rule| rule["flag"] }
    violation("capability declaration contract has duplicate flags") unless rule_ids.uniq.length == rule_ids.length
    violation("capability declaration contract flags must exactly match manifest feature flags") unless rule_ids.sort == flags

    rules.each { |rule| validate_rule(rule, manifest) }
  end

  def validate_rule(rule, manifest)
    flag = rule["flag"] || "<unknown flag>"
    %w[flag mode owner rationale reactivation_trigger].each do |field|
      violation("#{flag}: missing #{field}") if blank?(rule[field])
    end
    mode = rule["mode"]
    violation("#{flag}: invalid mode #{mode.inspect}") unless VALID_MODES.include?(mode)
    return unless manifest.key?(flag) && [true, false].include?(manifest[flag])

    case mode
    when "static_absence"
      validate_indicators(rule, "forbidden_indicators", flag)
      return if manifest[flag]

      matching_indicators(rule["forbidden_indicators"]).each do |match|
        violation("#{flag} is false but forbidden indicator #{match[:id]} exists in #{match[:path]}")
      end
    when "static_presence"
      validate_indicators(rule, "required_indicators", flag)
      return unless manifest[flag]

      indicators_without_match(rule["required_indicators"]).each do |indicator|
        violation("#{flag} is true but required indicator #{indicator['id']} is absent")
      end
    when "manual_attestation"
      evidence = rule["evidence"].to_s
      violation("#{flag}: manual attestation needs repository evidence") if evidence.empty? || !File.file?(absolute(evidence))
    end
  end

  def validate_indicators(rule, key, flag)
    indicators = Array(rule[key])
    violation("#{flag}: #{key} must not be empty") if indicators.empty?
    indicators.each do |indicator|
      %w[id paths pattern].each { |field| violation("#{flag}: indicator missing #{field}") if blank?(indicator[field]) }
      Array(indicator["paths"]).each { |path| violation("#{flag}: indicator path #{path} is missing") unless File.exist?(absolute(path)) }
      Regexp.new(indicator["pattern"].to_s)
    rescue RegexpError => error
      violation("#{flag}: indicator #{indicator['id']} has invalid pattern: #{error.message}")
    end
  end

  def matching_indicators(indicators)
    Array(indicators).flat_map do |indicator|
      matching_files(indicator).map { |path| { id: indicator["id"], path: relative(path) } }
    end
  end

  def indicators_without_match(indicators)
    Array(indicators).reject { |indicator| matching_files(indicator).any? }
  end

  def matching_files(indicator)
    regex = Regexp.new(indicator["pattern"])
    files_for(indicator["paths"]).select do |path|
      File.read(path, encoding: "UTF-8").match?(regex)
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      false
    end
  end

  def files_for(paths)
    Array(paths).flat_map do |path|
      absolute_path = absolute(path)
      if File.file?(absolute_path)
        [absolute_path]
      elsif Dir.exist?(absolute_path)
        Dir.glob(File.join(absolute_path, "**", "*")).select { |entry| File.file?(entry) && TEXT_EXTENSIONS.include?(File.extname(entry)) }
      else
        []
      end
    end
  end

  def relative(path)
    path.delete_prefix("#{@repo_root}/")
  end

  def blank?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  def violation(message)
    @violations << message
  end

  def build_report(manifest, contract)
    @report = {
      "schema_version" => "1.0",
      "generated_at" => Time.now.utc.iso8601,
      "decision" => violations.empty? ? "PASS" : "FAIL",
      "feature_flags" => manifest.select { |key, _| key.start_with?("feature_") },
      "rule_count" => Array(contract["rules"]).length,
      "violations" => violations,
    }
  end

  def write_report
    target = absolute(@report_path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, JSON.pretty_generate(report) + "\n")
  end
end

if $PROGRAM_NAME == __FILE__
  options = {
    repo_root: File.expand_path("../..", __dir__),
    report_path: ".quality/compliance-horizon/capability-declarations.json",
  }
  OptionParser.new do |parser|
    parser.on("--repo-root PATH") { |value| options[:repo_root] = value }
    parser.on("--report PATH") { |value| options[:report_path] = value }
  end.parse!

  validator = CapabilityDeclarationValidator.new(**options)
  if validator.run
    puts "Capability declarations PASS: #{validator.report['rule_count']} feature flags"
    exit 0
  end

  warn "Capability declarations FAIL:"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
