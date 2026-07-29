#!/usr/bin/env ruby

require "date"
require "minitest/autorun"
require "tmpdir"
require_relative "validate_supply_chain"

class SupplyChainGateTest < Minitest::Test
  def base_policy(exceptions = [])
    {
      "exception_policy" => {
        "maximum_validity_days" => 90,
        "required_fields" => %w[id kind owner reason approved_on expires_on],
        "allowed_kinds" => %w[vulnerability license action_reference],
      },
      "exceptions" => exceptions,
    }
  end

  def test_pinned_action_with_version_comment_passes
    Dir.mktmpdir do |directory|
      File.write(
        File.join(directory, "workflow.yml"),
        "steps:\n  - uses: actions/checkout@#{'a' * 40} # v7.0.1\n",
      )
      registry = SupplyChainGate::ExceptionRegistry.new(
        base_policy,
        today: Date.new(2026, 7, 28),
      )
      validator = SupplyChainGate::ActionReferenceValidator.new(
        directory,
        exception_registry: registry,
      )

      assert_empty validator.validate
    end
  end

  def test_mutable_action_tag_fails
    Dir.mktmpdir do |directory|
      File.write(
        File.join(directory, "workflow.yml"),
        "steps:\n  - uses: actions/checkout@v7\n",
      )
      registry = SupplyChainGate::ExceptionRegistry.new(
        base_policy,
        today: Date.new(2026, 7, 28),
      )
      validator = SupplyChainGate::ActionReferenceValidator.new(
        directory,
        exception_registry: registry,
      )

      assert_match(/full commit SHA/, validator.validate.join("\n"))
    end
  end

  def test_known_vulnerability_without_exception_fails
    registry = SupplyChainGate::ExceptionRegistry.new(
      base_policy,
      today: Date.new(2026, 7, 28),
    )
    report = osv_report("GHSA-test-0001")
    evaluator = SupplyChainGate::OsvFindingEvaluator.new(
      report,
      exception_registry: registry,
    )

    assert_match(
      /GHSA-test-0001/,
      evaluator.validate(["http"]).join("\n"),
    )
  end

  def test_unexpired_vulnerability_exception_passes
    exception = {
      "id" => "GHSA-test-0001",
      "kind" => "vulnerability",
      "owner" => "Engineering",
      "reason" => "Temporary mitigation is verified",
      "approved_on" => "2026-07-28",
      "expires_on" => "2026-08-15",
    }
    registry = SupplyChainGate::ExceptionRegistry.new(
      base_policy([exception]),
      today: Date.new(2026, 7, 28),
    )
    evaluator = SupplyChainGate::OsvFindingEvaluator.new(
      osv_report("GHSA-test-0001"),
      exception_registry: registry,
    )

    assert_empty registry.violations
    assert_empty evaluator.validate(["http"])
  end

  def test_expired_exception_is_rejected
    exception = {
      "id" => "GHSA-test-0001",
      "kind" => "vulnerability",
      "owner" => "Engineering",
      "reason" => "Expired test exception",
      "approved_on" => "2026-01-01",
      "expires_on" => "2026-01-20",
    }
    registry = SupplyChainGate::ExceptionRegistry.new(
      base_policy([exception]),
      today: Date.new(2026, 7, 28),
    )

    assert_match(/expired/, registry.violations.join("\n"))
    refute registry.approved?("vulnerability", "GHSA-test-0001")
  end

  def test_license_classifier_recognizes_permissive_licenses
    assert_equal(
      "Apache-2.0",
      SupplyChainGate::LicenseClassifier.classify(
        "example",
        "Apache License\nVersion 2.0, January 2004",
      ),
    )
    assert_equal(
      "MIT",
      SupplyChainGate::LicenseClassifier.classify(
        "example",
        "Permission is hereby granted, free of charge",
      ),
    )
    assert_equal(
      "BSD-3-Clause",
      SupplyChainGate::LicenseClassifier.classify(
        "example",
        "Redistribution and use in source and binary forms\nNeither the name",
      ),
    )
  end

  def test_swift_package_inspector_ignores_local_packages
    content = <<~SWIFT
      dependencies: [
        .package(path: "../local-package"),
        .package(url: "https://example.com/remote.git", from: "1.0.0"),
        .package(id: "example.remote", exact: "2.0.0"),
      ]
    SWIFT

    assert_equal(
      2,
      SupplyChainGate::SwiftPackageInspector.remote_declaration_count(content),
    )
  end

  def test_swift_package_inspector_uses_tracked_xcode_integration
    content = <<~PBXPROJ
      isa = XCLocalSwiftPackageReference;
      relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;
      productName = FlutterGeneratedPluginSwiftPackage;
    PBXPROJ

    assert(
      SupplyChainGate::SwiftPackageInspector.flutter_integration_enabled?(
        content,
      ),
    )
    refute(
      SupplyChainGate::SwiftPackageInspector.flutter_integration_enabled?(
        "swift_package_manager_enabled = true;",
      ),
    )
  end

  private

  def osv_report(vulnerability_id)
    {
      "results" => [
        {
          "packages" => [
            {
              "package" => {
                "name" => "http",
                "version" => "1.6.0",
                "ecosystem" => "Pub",
              },
              "vulnerabilities" => [
                { "id" => vulnerability_id },
              ],
            },
          ],
        },
      ],
    }
  end
end
