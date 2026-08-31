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
    "G-CLAIM-GOVERNANCE",
    "G-PRIVACY-BOUNDARY",
    "G-BACKEND-BOUNDARY",
    "G-RETENTION-OPS",
    "G-GATE-DEFINITION-QUALITY",
    "G-PROVIDER-DPA",
    "G-PROVIDER-SUBPROCESSORS",
    "G-COST-CONTROL",
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
    "EDPB-DPIA-WP248",
    "DE-UWG-EMP-CO",
    "OWASP-API-SECURITY-2023",
    "SUPABASE-API-KEYS",
    "SUPABASE-DPA",
    "SUPABASE-SUBPROCESSORS",
    "SUPABASE-COST-CONTROL",
    "SUPABASE-CRON",
    "SUPABASE-LOG-DRAINS",
    "SUPABASE-UPGRADING",
  ],
  "docs/project/compliance/provider-governance-register.yaml" => [
    "project_name: scanfair-dev",
    "region: eu-central-1",
    "personal_data_allowed: false",
    "pending_owner_approval",
    "remote_backend",
    "provider_approval_evidence",
    "qualified_review_confirmed",
    "provider_register_sha256",
  ],
  "docs/project/gate-definitions/gate-definition-schema.yaml" => [
    "scanfair-gate-v1",
    "core_attributes",
    "compatibility_profiles",
  ],
  "docs/project/compliance/claim-inventory.yaml" => [
    "Nährwert-Hinweis",
    "website_marketing",
    "blocked_pending_methodology_legal_and_domain_review",
  ],
  "docs/project/compliance/privacy-data-inventory.yaml" => [
    "request_network_metadata",
    "remote_backend_enabled: false",
    "screening_required_before_activation",
  ],
  "docs/project/compliance/privacy-data-flow.md" => [
    "Current Data Flow",
    "DPIA Decision Path",
  ],
  "docs/project/security/backend-threat-model.yaml" => [
    "accepted_for_definition_of_ready",
    "THR-012",
    "ABUSE-008",
    "remote_backend_enabled: false",
  ],
  "docs/project/security/eu-supabase-environment-contract.yaml" => [
    "eu-central-1",
    "allowed_key_types: [publishable]",
    "client_invocation_allowed: false",
    "maximum_response_bytes: 1048576",
    "environment_activation",
    "release_security",
  ],
  "docs/project/security/backend-threat-model.md" => [
    "Trust Boundaries",
    "G-BACKEND-BOUNDARY",
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
    "G-BACKEND-BOUNDARY",
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
