#!/usr/bin/env ruby

require "date"
require "digest"
require "fileutils"
require "json"
require "optparse"
require "pathname"
require "uri"
require "yaml"

module SupplyChainGate
  class ExceptionRegistry
    attr_reader :violations

    def initialize(policy, today: Date.today)
      @policy = policy
      @today = today
      @violations = []
      @valid = {}
      validate
    end

    def approved?(kind, id)
      @valid.key?([kind, id])
    end

    private

    def validate
      rules = @policy.fetch("exception_policy", {})
      required = Array(rules["required_fields"])
      allowed_kinds = Array(rules["allowed_kinds"])
      maximum_days = Integer(rules.fetch("maximum_validity_days", 0))
      exceptions = Array(@policy["exceptions"])
      seen = {}

      exceptions.each_with_index do |exception, index|
        location = "exceptions[#{index}]"
        required.each do |field|
          if exception[field].to_s.strip.empty?
            @violations << "#{location}: missing #{field}"
          end
        end

        id = exception["id"].to_s
        kind = exception["kind"].to_s
        key = [kind, id]
        @violations << "#{location}: duplicate #{kind} exception #{id}" if seen[key]
        seen[key] = true

        unless allowed_kinds.include?(kind)
          @violations << "#{location}: unsupported exception kind #{kind.inspect}"
        end

        begin
          approved_on = Date.iso8601(exception["approved_on"].to_s)
          expires_on = Date.iso8601(exception["expires_on"].to_s)
          validity_days = (expires_on - approved_on).to_i
          if validity_days.negative? || validity_days > maximum_days
            @violations <<
              "#{location}: validity #{validity_days} days exceeds 0..#{maximum_days}"
          end
          if expires_on < @today
            @violations << "#{location}: expired on #{expires_on}"
          end
        rescue Date::Error
          @violations << "#{location}: approved_on and expires_on must be ISO dates"
        end

        @valid[key] = exception unless @violations.any? do |message|
          message.start_with?("#{location}:")
        end
      end
    end
  end

  class ActionReferenceValidator
    ACTION_LINE = /^\s*(?:-\s*)?uses:\s*["']?([^"'#\s]+)["']?\s*(?:#\s*(.+))?$/
    FULL_SHA = /\A[0-9a-f]{40}\z/
    VERSION_COMMENT = /\Av\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?\b/

    attr_reader :references

    def initialize(workflow_dir, exception_registry:, require_version_comment: true)
      @workflow_dir = workflow_dir
      @exception_registry = exception_registry
      @require_version_comment = require_version_comment
      @references = []
    end

    def validate
      violations = []
      workflow_paths = Dir.glob(File.join(@workflow_dir, "**", "*.{yml,yaml}")).sort
      if workflow_paths.empty?
        return ["#{relative(@workflow_dir)}: no GitHub workflows found"]
      end

      workflow_paths.each do |path|
        File.readlines(path, chomp: true).each_with_index do |line, index|
          match = ACTION_LINE.match(line)
          next unless match

          reference = match[1]
          comment = match[2].to_s.strip
          entry = {
            "workflow" => relative(path),
            "line" => index + 1,
            "reference" => reference,
          }
          @references << entry
          next if reference.start_with?("./")

          if reference.start_with?("docker://")
            unless reference.match?(/@sha256:[0-9a-f]{64}\z/)
              violations << "#{relative(path)}:#{index + 1}: Docker action is not digest-pinned"
            end
            next
          end

          action, separator, revision = reference.rpartition("@")
          location = "#{relative(path)}:#{index + 1}"
          unless separator == "@" && action.include?("/") && FULL_SHA.match?(revision)
            unless @exception_registry.approved?("action_reference", reference)
              violations << "#{location}: external action must use a full commit SHA: #{reference}"
            end
            next
          end

          entry["action"] = action
          entry["commit_sha"] = revision
          entry["version_comment"] = comment
          if @require_version_comment && !VERSION_COMMENT.match?(comment)
            violations << "#{location}: pinned action requires a release comment such as # v1.2.3"
          end
        end
      end
      violations
    end

    private

    def relative(path)
      Pathname(path).relative_path_from(Pathname(Dir.pwd)).to_s
    rescue ArgumentError
      path
    end
  end

  class LicenseClassifier
    def self.classify(package_name, text)
      return "LicenseRef-Flutter-SDK-Composite" if package_name == "sky_engine"
      return "Apache-2.0" if text.match?(/Apache License\s*\n?\s*Version 2\.0/i)
      return "MIT" if text.include?("Permission is hereby granted, free of charge")

      if text.include?("Redistribution and use in source and binary forms") &&
          text.include?("Neither the name")
        return "BSD-3-Clause"
      end

      "UNKNOWN"
    end
  end

  class SwiftPackageInspector
    REMOTE_DECLARATION = /\.package\s*\(\s*(?:url|id)\s*:/

    def self.remote_declaration_count(content)
      content.scan(REMOTE_DECLARATION).length
    end
  end

  class OsvFindingEvaluator
    attr_reader :package_count, :vulnerability_count

    def initialize(report, exception_registry:)
      @report = report
      @exception_registry = exception_registry
      @package_count = 0
      @vulnerability_count = 0
    end

    def validate(expected_packages)
      violations = []
      scanned_packages = []
      results = Array(@report["results"])
      if results.empty?
        return ["OSV report contains no scan results"]
      end

      results.each do |result|
        Array(result["packages"]).each do |package_result|
          package = package_result.fetch("package", {})
          name = package["name"].to_s
          scanned_packages << name unless name.empty?
          Array(package_result["vulnerabilities"]).each do |vulnerability|
            @vulnerability_count += 1
            id = vulnerability["id"].to_s
            id = "UNKNOWN-VULNERABILITY" if id.empty?
            next if @exception_registry.approved?("vulnerability", id)

            violations << "known vulnerability #{id} affects #{name}"
          end
        end
      end

      scanned_packages.uniq!
      @package_count = scanned_packages.length
      missing = expected_packages - scanned_packages
      unexpected = scanned_packages - expected_packages
      missing.each { |name| violations << "OSV report is missing locked package #{name}" }
      unexpected.each { |name| violations << "OSV report contains unlocked package #{name}" }
      violations
    end
  end

  class Validator
    attr_reader :violations

    def initialize(repo_root:, policy_path:, osv_report_path:, inventory_path:)
      @repo_root = File.expand_path(repo_root)
      @policy_path = absolute(policy_path)
      @osv_report_path = absolute(osv_report_path)
      @inventory_path = absolute(inventory_path)
      @violations = []
      @inventory = {}
    end

    def run
      Dir.chdir(@repo_root) do
        policy = load_yaml(@policy_path)
        validate_policy(policy)
        exceptions = ExceptionRegistry.new(policy)
        @violations.concat(exceptions.violations)

        action_validator = ActionReferenceValidator.new(
          absolute(policy.dig("scope", "github_workflows")),
          exception_registry: exceptions,
          require_version_comment: policy.dig(
            "github_actions_policy",
            "require_version_comment",
          ) == true,
        )
        @violations.concat(action_validator.validate)

        packages, package_config = validate_dart_dependencies(policy, exceptions)
        native_plugins = validate_native_ios(policy, packages, package_config)
        osv = validate_osv_report(packages.keys.sort, exceptions)

        @inventory["schema_version"] = "1.0"
        @inventory["lockfile"] = relative(absolute(policy.dig("scope", "dart_lockfile")))
        @inventory["lockfile_sha256"] = file_hash(
          absolute(policy.dig("scope", "dart_lockfile")),
        )
        @inventory["dart_packages"] = packages.values.sort_by { |item| item["name"] }
        @inventory["native_ios_plugins"] = native_plugins
        @inventory["github_actions"] = action_validator.references
        @inventory["osv"] = {
          "scanner_version" => policy.dig("vulnerability_policy", "version"),
          "scanned_packages" => osv&.package_count || 0,
          "reported_vulnerabilities" => osv&.vulnerability_count || 0,
        }
        write_inventory
      end

      if @violations.empty?
        puts(
          "Supply-chain validation OK: " \
          "#{@inventory.fetch('dart_packages').length} Dart packages, " \
          "#{@inventory.fetch('native_ios_plugins').length} iOS plugins, " \
          "#{@inventory.fetch('github_actions').length} Action references, " \
          "#{@inventory.dig('osv', 'reported_vulnerabilities')} vulnerabilities",
        )
        true
      else
        warn "Supply-chain validation failed:"
        @violations.each { |violation| warn "- #{violation}" }
        false
      end
    rescue Errno::ENOENT, JSON::ParserError, Psych::SyntaxError, KeyError => error
      warn "Supply-chain validation failed:"
      warn "- technical validation error: #{error.message}"
      false
    end

    private

    def validate_policy(policy)
      %w[
        schema_version
        last_reviewed
        owner
        scope
        vulnerability_policy
        license_policy
        github_actions_policy
        native_ios_policy
        exception_policy
        exceptions
      ].each do |field|
        @violations << "supply-chain policy: missing #{field}" unless policy.key?(field)
      end

      version = policy.dig("vulnerability_policy", "version").to_s
      @violations << "supply-chain policy: missing OSV version" if version.empty?
      binaries = policy.dig("vulnerability_policy", "binaries")
      if !binaries.is_a?(Hash) || binaries.empty?
        @violations << "supply-chain policy: OSV binary checksums are missing"
      end
    end

    def validate_dart_dependencies(policy, exceptions)
      lockfile_path = absolute(policy.dig("scope", "dart_lockfile"))
      package_config_path = absolute(policy.dig("scope", "dart_package_config"))
      lockfile = load_yaml(lockfile_path)
      locked = lockfile.fetch("packages")
      package_config = JSON.parse(File.read(package_config_path))
      configured = Array(package_config["packages"]).to_h do |package|
        [package["name"], package]
      end
      allowed_licenses = Array(policy.dig("license_policy", "allowed_identifiers"))
      inventory = {}

      locked.keys.sort.each do |name|
        details = locked.fetch(name)
        config = configured[name]
        if config.nil?
          @violations << "package config is missing locked package #{name}"
          next
        end

        package_root = package_root_for(config, package_config_path)
        license_path, inherited = find_license(
          package_root,
          allow_parent_lookup: details["source"] == "sdk",
        )
        license_id = "MISSING"
        license_sha = nil
        if license_path
          license_text = File.read(license_path, encoding: "UTF-8", invalid: :replace)
          license_id = LicenseClassifier.classify(name, license_text)
          license_sha = file_hash(license_path)
        end

        coordinate = "#{name}@#{details['version']}"
        unless allowed_licenses.include?(license_id) ||
            exceptions.approved?("license", coordinate)
          @violations <<
            "#{coordinate}: license #{license_id} is missing, unknown or not allowed"
        end

        inventory[name] = {
          "name" => name,
          "version" => details["version"].to_s,
          "dependency_type" => details["dependency"].to_s,
          "source" => details["source"].to_s,
          "license" => license_id,
          "license_sha256" => license_sha,
          "license_inherited_from_sdk" => inherited,
        }
      end
      [inventory, configured]
    end

    def validate_native_ios(policy, packages, package_config)
      plugin_path = absolute(policy.dig("scope", "flutter_plugin_inventory"))
      plugin_data = JSON.parse(File.read(plugin_path))
      swift_enabled = plugin_data.dig("swift_package_manager_enabled", "ios")
      expected = policy.dig("native_ios_policy", "expected_integration")
      if expected == "flutter_swift_package_manager" && swift_enabled != true
        @violations << "iOS Flutter Swift Package Manager integration is not enabled"
      end

      podfile_lock = File.join(@repo_root, "esg_app/ios/Podfile.lock")
      if File.file?(podfile_lock) &&
          policy.dig("native_ios_policy", "allow_unreviewed_cocoapods_lockfile") != true
        @violations << "unreviewed CocoaPods lockfile detected: #{relative(podfile_lock)}"
      end

      resolved_files = Dir.glob(File.join(@repo_root, "esg_app/ios/**/Package.resolved"))
      if resolved_files.any? &&
          policy.dig("native_ios_policy", "allow_unlocked_remote_swift_packages") != true
        @violations <<
          "remote Swift package lockfiles require explicit review: " \
          "#{resolved_files.map { |path| relative(path) }.join(', ')}"
      end

      Array(plugin_data.dig("plugins", "ios")).sort_by { |plugin| plugin["name"] }.map do |plugin|
        name = plugin["name"].to_s
        config = package_config[name]
        unless packages.key?(name) && config
          @violations << "iOS plugin #{name} is not present in the Dart lock inventory"
          next({ "name" => name, "status" => "missing_from_lockfile" })
        end

        root = package_root_for(
          config,
          absolute(policy.dig("scope", "dart_package_config")),
        )
        manifests = Dir.glob(File.join(root, "**", "Package.swift")).sort
        if plugin["native_build"] == true && manifests.empty?
          @violations << "native iOS plugin #{name} has no Package.swift manifest"
        end

        manifest_entries = manifests.map do |manifest|
          content = File.read(manifest)
          remote_count = SwiftPackageInspector.remote_declaration_count(content)
          if remote_count.positive? &&
              policy.dig(
                "native_ios_policy",
                "allow_unlocked_remote_swift_packages",
              ) != true
            @violations <<
              "iOS plugin #{name} declares #{remote_count} unreviewed Swift package(s)"
          end
          {
            "path" => manifest.sub("#{root}/", ""),
            "sha256" => file_hash(manifest),
            "remote_package_declarations" => remote_count,
          }
        end

        {
          "name" => name,
          "version" => packages.dig(name, "version"),
          "native_build" => plugin["native_build"] == true,
          "plugin_dependencies" => Array(plugin["dependencies"]).sort,
          "swift_manifests" => manifest_entries,
        }
      end
    end

    def validate_osv_report(expected_packages, exceptions)
      report = JSON.parse(File.read(@osv_report_path))
      evaluator = OsvFindingEvaluator.new(report, exception_registry: exceptions)
      @violations.concat(evaluator.validate(expected_packages))
      evaluator
    end

    def find_license(package_root, allow_parent_lookup:)
      current = package_root
      6.times do |depth|
        candidates = %w[LICENSE LICENSE.txt LICENSE.md COPYING COPYING.txt].map do |name|
          File.join(current, name)
        end
        found = candidates.find { |path| File.file?(path) }
        return [found, depth.positive?] if found
        break unless allow_parent_lookup

        parent = File.dirname(current)
        break if parent == current

        current = parent
      end
      [nil, false]
    end

    def package_root_for(config, package_config_path)
      root_uri = config.fetch("rootUri")
      uri = URI.parse(root_uri)
      if uri.scheme == "file"
        URI::DEFAULT_PARSER.unescape(uri.path)
      else
        File.expand_path(root_uri, File.dirname(package_config_path))
      end
    end

    def load_yaml(path)
      YAML.safe_load(
        File.read(path),
        permitted_classes: [Date],
        aliases: true,
      )
    end

    def write_inventory
      FileUtils.mkdir_p(File.dirname(@inventory_path))
      File.write(@inventory_path, "#{JSON.pretty_generate(@inventory)}\n")
    end

    def file_hash(path)
      File.file?(path) ? Digest::SHA256.file(path).hexdigest : nil
    end

    def absolute(path)
      File.expand_path(path.to_s, @repo_root)
    end

    def relative(path)
      Pathname(path).relative_path_from(Pathname(@repo_root)).to_s
    rescue ArgumentError
      path
    end
  end
end

if $PROGRAM_NAME == __FILE__
  repo_root = File.expand_path("../..", __dir__)
  options = {
    policy: "docs/project/compliance/supply-chain-policy.yaml",
    osv_report: ".quality/supply-chain/osv-results.json",
    inventory: ".quality/supply-chain/dependency-inventory.json",
  }
  OptionParser.new do |parser|
    parser.on("--policy PATH") { |value| options[:policy] = value }
    parser.on("--osv-report PATH") { |value| options[:osv_report] = value }
    parser.on("--inventory PATH") { |value| options[:inventory] = value }
  end.parse!

  validator = SupplyChainGate::Validator.new(
    repo_root: repo_root,
    policy_path: options[:policy],
    osv_report_path: options[:osv_report],
    inventory_path: options[:inventory],
  )
  exit(validator.run ? 0 : 1)
end
