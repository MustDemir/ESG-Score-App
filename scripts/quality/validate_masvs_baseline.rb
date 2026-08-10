#!/usr/bin/env ruby

require "date"
require "fileutils"
require "json"
require "optparse"
require "yaml"

module MasvsGate
  REQUIRED_CONTROL_IDS = %w[
    MASVS-STORAGE-1 MASVS-STORAGE-2
    MASVS-CRYPTO-1 MASVS-CRYPTO-2
    MASVS-AUTH-1 MASVS-AUTH-2 MASVS-AUTH-3
    MASVS-NETWORK-1 MASVS-NETWORK-2
    MASVS-PLATFORM-1 MASVS-PLATFORM-2 MASVS-PLATFORM-3
    MASVS-CODE-1 MASVS-CODE-2 MASVS-CODE-3 MASVS-CODE-4
    MASVS-RESILIENCE-1 MASVS-RESILIENCE-2
    MASVS-RESILIENCE-3 MASVS-RESILIENCE-4
    MASVS-PRIVACY-1 MASVS-PRIVACY-2
    MASVS-PRIVACY-3 MASVS-PRIVACY-4
  ].freeze
  PROFILES = %w[development release_candidate submission].freeze
  REQUIREMENTS = %w[MUST SHOULD NOT_APPLICABLE].freeze
  STATUSES = %w[pass partial open not_applicable].freeze
  VERIFICATION_TYPES = %w[AUTO HYBRID MANUAL NONE].freeze

  def self.load_yaml(path)
    YAML.safe_load(
      File.read(path),
      permitted_classes: [Date],
      aliases: true,
    )
  end

  class Validator
    attr_reader :violations, :warnings, :controls, :manual_checks, :profile

    def initialize(repo_root:, baseline:, checklist:, profile:, verify_repository: true)
      @repo_root = repo_root
      @baseline = baseline
      @checklist = checklist
      @profile = profile
      @verify_repository = verify_repository
      @violations = []
      @warnings = []
      @controls = Array(baseline["controls"])
      @manual_checks = Array(checklist["checks"])
    end

    def validate
      validate_header
      validate_controls
      validate_manual_checks
      validate_repository if @verify_repository
      validate_profile
      self
    end

    def success?
      violations.empty?
    end

    def report
      {
        "gate" => "G-LOCAL-MASVS",
        "baseline" => @baseline["baseline_id"],
        "baseline_version" => @baseline["version"],
        "standard_version" => @baseline.dig("standard", "version"),
        "profile" => profile,
        "decision" => success? ? "PASS" : "FAIL",
        "counts" => {
          "total" => controls.length,
          "applicable" => controls.count { |item| item["applicability"] == "applicable" },
          "not_applicable" => controls.count { |item| item["applicability"] == "not_applicable" },
          "must" => controls.count { |item| item["requirement"] == "MUST" },
          "should" => controls.count { |item| item["requirement"] == "SHOULD" },
          "pass" => controls.count { |item| item["status"] == "pass" },
          "open_or_partial" => controls.count { |item| %w[open partial].include?(item["status"]) },
        },
        "violations" => violations,
        "warnings" => warnings,
      }
    end

    private

    def validate_header
      unless PROFILES.include?(profile)
        violations << "unsupported profile #{profile.inspect}"
      end
      %w[schema_version baseline_id version owner standard scope profiles controls].each do |field|
        violations << "baseline: missing #{field}" unless @baseline.key?(field)
      end
      if @baseline.dig("standard", "version") != "2.1.0"
        violations << "baseline: standard.version must be 2.1.0"
      end
      if @baseline.dig("standard", "control_count") != REQUIRED_CONTROL_IDS.length
        violations << "baseline: standard.control_count must be #{REQUIRED_CONTROL_IDS.length}"
      end
      PROFILES.each do |required_profile|
        unless @baseline.fetch("profiles", {}).key?(required_profile)
          violations << "baseline: missing profile #{required_profile}"
        end
      end
    end

    def validate_controls
      ids = controls.map { |control| control["id"] }
      duplicate_ids(ids).each { |id| violations << "baseline: duplicate control #{id}" }
      (REQUIRED_CONTROL_IDS - ids).each { |id| violations << "baseline: missing control #{id}" }
      (ids - REQUIRED_CONTROL_IDS).each { |id| violations << "baseline: unknown control #{id}" }

      controls.each do |control|
        id = control["id"] || "control-without-id"
        %w[group objective applicability requirement status verification rationale release_blocking evidence].each do |field|
          value = control[field]
          if value.nil? || (value.respond_to?(:empty?) && value.empty?)
            violations << "#{id}: missing #{field}"
          end
        end
        unless REQUIREMENTS.include?(control["requirement"])
          violations << "#{id}: invalid requirement #{control['requirement'].inspect}"
        end
        unless STATUSES.include?(control["status"])
          violations << "#{id}: invalid status #{control['status'].inspect}"
        end
        unless VERIFICATION_TYPES.include?(control["verification"])
          violations << "#{id}: invalid verification #{control['verification'].inspect}"
        end
        validate_applicability(control)
        validate_evidence(control)
      end
    end

    def validate_applicability(control)
      id = control["id"]
      case control["applicability"]
      when "not_applicable"
        if control["requirement"] != "NOT_APPLICABLE" || control["status"] != "not_applicable"
          violations << "#{id}: non-applicable control must use NOT_APPLICABLE/not_applicable"
        end
        if control["activation_trigger"].to_s.strip.empty?
          violations << "#{id}: non-applicable control requires activation_trigger"
        end
        violations << "#{id}: non-applicable control cannot block release" if control["release_blocking"]
        unless control["verification"] == "NONE"
          violations << "#{id}: non-applicable control must use NONE verification"
        end
      when "applicable"
        if control["requirement"] == "NOT_APPLICABLE" || control["status"] == "not_applicable"
          violations << "#{id}: applicable control cannot be NOT_APPLICABLE"
        end
        expected_blocking = control["requirement"] == "MUST"
        if control["release_blocking"] != expected_blocking
          violations << "#{id}: release_blocking must be #{expected_blocking} for #{control['requirement']}"
        end
        if %w[HYBRID MANUAL].include?(control["verification"]) && Array(control["manual_check_ids"]).empty?
          violations << "#{id}: #{control['verification']} verification requires manual_check_ids"
        end
      else
        violations << "#{id}: invalid applicability #{control['applicability'].inspect}"
      end
    end

    def validate_evidence(control)
      Array(control["evidence"]).each do |reference|
        next if reference.to_s.start_with?("https://")

        path = File.join(@repo_root, reference.to_s)
        violations << "#{control['id']}: missing evidence path #{reference}" unless File.exist?(path)
      end
    end

    def validate_manual_checks
      ids = manual_checks.map { |check| check["id"] }
      duplicate_ids(ids).each { |id| violations << "checklist: duplicate check #{id}" }

      manual_checks.each do |check|
        id = check["id"] || "check-without-id"
        %w[control_ids profile status title procedure acceptance evidence_file].each do |field|
          value = check[field]
          if value.nil? || (value.respond_to?(:empty?) && value.empty?)
            violations << "#{id}: missing #{field}"
          end
        end
        unless %w[pass fail not_run].include?(check["status"])
          violations << "#{id}: invalid checklist status #{check['status'].inspect}"
        end
        Array(check["control_ids"]).each do |control_id|
          violations << "#{id}: unknown control #{control_id}" unless REQUIRED_CONTROL_IDS.include?(control_id)
        end
      end

      controls.each do |control|
        Array(control["manual_check_ids"]).each do |check_id|
          check = manual_checks.find { |item| item["id"] == check_id }
          unless check
            violations << "#{control['id']}: unknown manual check #{check_id}"
            next
          end
          unless Array(check["control_ids"]).include?(control["id"])
            violations << "#{control['id']}: manual check #{check_id} lacks reciprocal mapping"
          end
        end
      end
    end

    def validate_repository
      validate_absent_capabilities
      validate_platform_surface
      validate_ios_target
      validate_network_security
      validate_input_handling
      validate_privacy_surface
      validate_supply_chain_evidence
    end

    def validate_absent_capabilities
      dependencies = @baseline_dependencies
      dependencies ||= MasvsGate.load_yaml(File.join(@repo_root, "esg_app/pubspec.yaml"))
        .fetch("dependencies", {}).keys
      forbidden_by_capability = {
        "intentional_sensitive_local_storage" => %w[shared_preferences hive hive_flutter sqflite drift isar flutter_secure_storage],
        "custom_cryptography_or_keys" => %w[cryptography pointycastle encrypt],
        "accounts_or_local_authentication" => %w[supabase_flutter firebase_auth local_auth sign_in_with_apple],
        "ipc_deep_links_or_extensions" => %w[app_links uni_links share_plus],
        "webviews" => %w[webview_flutter flutter_inappwebview],
      }
      capabilities = @baseline.dig("scope", "capabilities") || {}
      forbidden_by_capability.each do |capability, packages|
        next unless capabilities[capability] == false

        present = dependencies & packages
        unless present.empty?
          violations << "scope capability #{capability} is false but dependencies include #{present.join(', ')}"
        end
      end

      if capabilities["intentional_sensitive_local_storage"] == false
        dart_sources = Dir.glob(File.join(@repo_root, "esg_app/lib/**/*.dart"))
          .map { |path| File.read(path) }.join("\n")
        if dart_sources.include?("import 'dart:io'") || dart_sources.match?(/\bFile\s*\(/)
          violations << "scope excludes local storage but application Dart code uses file APIs"
        end
      end
    end

    def validate_platform_surface
      capabilities = @baseline.dig("scope", "capabilities") || {}
      info_plist = read("esg_app/ios/Runner/Info.plist")
      project = read("esg_app/ios/Runner.xcodeproj/project.pbxproj")

      if capabilities["ipc_deep_links_or_extensions"] == false
        if info_plist.include?("CFBundleURLTypes") ||
            project.match?(/com\.apple\.developer\.(associated-domains|application-groups)/)
          violations << "scope excludes IPC/deep links but iOS URL or entitlement configuration exists"
        end
        entitlements = Dir.glob(File.join(@repo_root, "esg_app/ios/**/*.entitlements"))
        unless entitlements.empty?
          violations << "scope excludes IPC/deep links but entitlement files exist: #{entitlements.map { |path| relative(path) }.join(', ')}"
        end
      end

      return unless capabilities["webviews"] == false

      source_paths = Dir.glob(File.join(@repo_root, "esg_app/{lib,ios/Runner}/**/*.{dart,swift,m,mm}"))
      webview_reference = source_paths.find do |path|
        File.read(path).match?(/\b(?:WKWebView|UIWebView|WebViewWidget|InAppWebView)\b/)
      end
      if webview_reference
        violations << "scope excludes WebViews but #{relative(webview_reference)} references a WebView API"
      end
    end

    def validate_ios_target
      project = read("esg_app/ios/Runner.xcodeproj/project.pbxproj")
      targets = project.scan(/IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);/).flatten.uniq
      expected = @baseline.dig("scope", "minimum_ios_version")
      violations << "iOS deployment target #{targets.inspect} does not match baseline #{expected}" unless targets == [expected]
    end

    def validate_network_security
      service = read("esg_app/lib/services/open_food_facts_service.dart")
      info_plist = read("esg_app/ios/Runner/Info.plist")
      violations << "network client must construct requests with Uri.https" unless service.include?("Uri.https(")
      configured_hosts = service.scan(/static const _host = '([^']+)'/).flatten.sort
      baseline_hosts = Array(@baseline.dig("scope", "network_endpoints"))
        .map { |endpoint| endpoint["host"] }.compact.sort
      unless configured_hosts == baseline_hosts
        violations << "network hosts #{configured_hosts.inspect} do not match baseline #{baseline_hosts.inspect}"
      end
      if info_plist.match?(/<key>NSAllowsArbitraryLoads<\/key>\s*<true\/>/m)
        violations << "Info.plist enables NSAllowsArbitraryLoads"
      end
      Dir.glob(File.join(@repo_root, "esg_app/lib/**/*.dart")).each do |path|
        File.readlines(path).each_with_index do |line, index|
          next if line.lstrip.start_with?("//")
          if line.include?("http://")
            violations << "#{relative(path)}:#{index + 1}: cleartext runtime URL"
          end
        end
      end
    end

    def validate_input_handling
      service = read("esg_app/lib/services/open_food_facts_service.dart")
      mapper = read("esg_app/lib/data_sources/open_food_facts_product_mapper.dart")
      tests = read("esg_app/test/services/open_food_facts_service_test.dart")
      score_tests = read("esg_app/test/services/esg_score_calculator_test.dart")
      violations << "barcode input must enforce an 8-14 digit boundary" unless service.match?(/\\d\{8,14\}/)
      violations << "remote numeric inputs must reject non-finite values" unless mapper.include?("isFinite")
      unless tests.include?("ProductLookupFailureType.invalidBarcode")
        violations << "invalid barcode behavior requires a test"
      end
      violations << "non-finite score handling requires a test" unless score_tests.include?("non-finite")
    end

    def validate_privacy_surface
      pubspec = MasvsGate.load_yaml(File.join(@repo_root, "esg_app/pubspec.yaml"))
      dependencies = pubspec.fetch("dependencies", {}).keys
      analytics = %w[firebase_analytics amplitude_flutter mixpanel_flutter appcenter_analytics]
      present = dependencies & analytics
      violations << "tracking-disabled baseline conflicts with analytics packages: #{present.join(', ')}" unless present.empty?

      info_plist = read("esg_app/ios/Runner/Info.plist")
      permission_keys = info_plist.scan(/<key>(NS[A-Za-z]+UsageDescription)<\/key>/).flatten.uniq
      unless permission_keys == ["NSCameraUsageDescription"]
        violations << "iOS permission inventory #{permission_keys.inspect} differs from camera-only baseline"
      end
      privacy = read("esg_app/ios/Runner/PrivacyInfo.xcprivacy")
      unless privacy.match?(/<key>NSPrivacyTracking<\/key>\s*<false\/>/m)
        violations << "privacy manifest must declare tracking false"
      end
    end

    def validate_supply_chain_evidence
      %w[esg_app/pubspec.lock scripts/quality/run_supply_chain_gate.sh docs/project/compliance/supply-chain-policy.yaml].each do |path|
        violations << "missing supply-chain evidence #{path}" unless File.file?(File.join(@repo_root, path))
      end
    end

    def validate_profile
      controls.each do |control|
        next unless control["applicability"] == "applicable"
        next if control["status"] == "pass"

        message = "#{control['id']}: #{control['requirement']} control is #{control['status']}"
        if %w[release_candidate submission].include?(profile) && control["requirement"] == "MUST"
          violations << message
        else
          warnings << message
        end
      end

      return if profile == "development"

      controls.each do |control|
        next unless control["applicability"] == "applicable"
        next unless control["requirement"] == "MUST"

        Array(control["manual_check_ids"]).each do |check_id|
          check = manual_checks.find { |item| item["id"] == check_id }
          next if check && check["status"] == "pass"

          violations << "#{control['id']}: manual check #{check_id} is not passed"
        end
      end
    end

    def duplicate_ids(ids)
      counts = ids.compact.each_with_object(Hash.new(0)) do |id, result|
        result[id] += 1
      end
      counts.select { |_id, count| count > 1 }.keys
    end

    def read(relative_path)
      File.read(File.join(@repo_root, relative_path))
    end

    def relative(path)
      path.delete_prefix("#{@repo_root}/")
    end
  end

  def self.write_report(repo_root, report)
    directory = File.join(repo_root, ".quality/masvs")
    FileUtils.mkdir_p(directory)
    File.write(File.join(directory, "masvs-baseline-report.json"), JSON.pretty_generate(report) + "\n")
    markdown = <<~MARKDOWN
      # OWASP MASVS Gate Report

      - Decision: #{report['decision']}
      - Profile: #{report['profile']}
      - Standard: OWASP MASVS #{report['standard_version']}
      - Controls: #{report.dig('counts', 'total')}
      - Applicable: #{report.dig('counts', 'applicable')}
      - Not applicable: #{report.dig('counts', 'not_applicable')}
      - Open or partial: #{report.dig('counts', 'open_or_partial')}

      ## Violations

      #{report['violations'].empty? ? '- None' : report['violations'].map { |item| "- #{item}" }.join("\n")}

      ## Warnings

      #{report['warnings'].empty? ? '- None' : report['warnings'].map { |item| "- #{item}" }.join("\n")}
    MARKDOWN
    File.write(File.join(directory, "masvs-baseline-report.md"), markdown)
  end
end

if $PROGRAM_NAME == __FILE__
  options = { profile: ENV.fetch("COMPLIANCE_PROFILE", "development") }
  OptionParser.new do |parser|
    parser.on("--profile PROFILE") { |value| options[:profile] = value }
  end.parse!

  repo_root = File.expand_path("../..", __dir__)
  baseline = MasvsGate.load_yaml(File.join(repo_root, "docs/project/compliance/owasp-masvs-ios-baseline.yaml"))
  checklist = MasvsGate.load_yaml(File.join(repo_root, "docs/project/compliance/owasp-masvs-ios-manual-checklist.yaml"))
  validator = MasvsGate::Validator.new(
    repo_root: repo_root,
    baseline: baseline,
    checklist: checklist,
    profile: options[:profile],
  ).validate
  MasvsGate.write_report(repo_root, validator.report)

  puts "OWASP MASVS #{baseline.dig('standard', 'version')} controls: #{validator.controls.length}"
  puts "Profile: #{validator.profile}"
  validator.warnings.each { |warning| warn "WARN: #{warning}" }
  if validator.success?
    puts "G-LOCAL-MASVS: PASS"
    exit 0
  end

  warn "G-LOCAL-MASVS: FAIL"
  validator.violations.each { |violation| warn "- #{violation}" }
  exit 1
end
