#!/usr/bin/env ruby

repo_root = File.expand_path("../..", __dir__)
checks = {
  "README.md" => [
    "Quality Gates",
    "scripts/quality/run_quality_gates.sh",
    "G-FLT-COVERAGE",
    "G-IOS-COMPILE",
    "G-CMP-SCHEMA",
    "G-DATA-ARCH",
    "G-DATA-LICENSE",
    "G-METHOD-CATALOG",
    "G-LINK-INTEGRITY",
    "G-MISSING-DATA",
    "G-RED-FLAG",
    "G-SCORE-REPRO",
    "G-CLAIM-SAFETY",
    "G-PROJECT-CONTROL",
    "G-SUPPLY-CHAIN",
    "AGRIBALYSE 3.2",
    "G-AS-CLAIMS-TRANSPARENCY",
    "Delivery Operating Model",
    "Product Engineering Handbook",
    "Lifecycle Gap Analysis",
    "Verbesserungsregister",
  ],
  "docs/project/delivery-operating-model.md" => [
    "Vier Ebenen",
    "Definition of Done",
    "Gate-Aufnahmeregel",
    "release_candidate",
  ],
  "docs/project/improvement-register.yaml" => [
    "IMP-PROC-001",
    "IMP-PROC-003",
    "IMP-COMP-001",
    "IMP-COMP-004",
    "IMP-DEV-001",
    "IMP-DEV-003",
    "IMP-OPS-001",
  ],
  "docs/project/gap-register.yaml" => [
    "GAP-001",
    "GAP-014",
    "maturity_current",
    "closure_criteria",
  ],
  "docs/project/methodology/gap-analysis-process.md" => [
    "Zwölf Prüffelder",
    "Acht Lifecycle-Phasen",
    "External Horizon Scan",
    "Closure und Regression",
  ],
  "docs/project/compliance/supply-chain-policy.yaml" => [
    "OSV-Scanner",
    "require_full_length_commit_sha",
    "maximum_validity_days",
  ],
  "docs/project/compliance/apple-compliance-control-model.md" => [
    "release_candidate",
  ],
  "docs/project/compliance/source-register.yaml" => [
    "APPLE-ARG",
  ],
  "esg_app/README.md" => [
    "flutter run",
    "Open Food Facts API v3",
    "mobile_scanner",
  ],
  "docs/project/data/data-architecture.md" => [
    "ESGEvidence",
    "retrieval channel",
    "traceability_relationships",
    "license-composition-policy.yaml",
    "G-DATA-LICENSE",
  ],
  "docs/project/data/license-composition-policy.yaml" => [
    "produced_work",
    "derivative_database",
    "collective_database_candidate",
    "enforce_cached_product_license_boundary",
  ],
  "docs/project/methodology-catalog/README.md" => [
    "2.0-draft",
    "active_in_formula: false",
    "scoring-controls.yaml",
  ],
  "supabase/README.md" => [
    "supabase db reset --local",
  ],
}.freeze

violations = []
marker_count = 0

checks.each do |relative_path, markers|
  path = File.join(repo_root, relative_path)
  unless File.file?(path)
    violations << "#{relative_path}: file is missing"
    next
  end

  content = File.read(path, encoding: "UTF-8")
  markers.each do |marker|
    marker_count += 1
    unless content.include?(marker)
      violations << "#{relative_path}: missing marker #{marker.inspect}"
    end
  end
end

if violations.empty?
  puts "Documentation traceability OK: #{marker_count} working-tree markers"
  exit 0
end

warn "Documentation traceability validation failed:"
violations.each { |violation| warn "- #{violation}" }
exit 1
