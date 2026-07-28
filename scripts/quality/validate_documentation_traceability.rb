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
    "G-METHOD-CATALOG",
    "G-LINK-INTEGRITY",
    "G-MISSING-DATA",
    "G-RED-FLAG",
    "G-SCORE-REPRO",
    "G-CLAIM-SAFETY",
    "G-PROJECT-CONTROL",
    "AGRIBALYSE 3.2",
    "G-AS-CLAIMS-TRANSPARENCY",
    "Delivery Operating Model",
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
    "IMP-COMP-001",
    "IMP-DEV-001",
    "IMP-OPS-001",
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

  content = File.binread(path)
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
