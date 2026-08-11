#!/usr/bin/env ruby

require "yaml"

repo_root = File.expand_path("../..", __dir__)
migration_files = Dir.glob(
  File.join(repo_root, "supabase", "migrations", "*.sql")
).sort
violations = []

if migration_files.empty?
  violations << "No Supabase migration found"
else
  sql = migration_files.map { |path| File.read(path) }.join("\n").downcase
  tables = %w[
    data_sources
    cached_products
    product_evidence
    score_snapshots
    scans
    methodology_versions
    parameters
    category_profiles
    profile_parameters
    source_mappings
    traceability_entities
    traceability_entity_identifiers
    traceability_relationships
  ]

  tables.each do |table|
    unless sql.match?(/create table if not exists public\.#{table}\b/)
      violations << "Missing table public.#{table}"
    end
    unless sql.match?(
      /alter table public\.#{table} enable row level security\s*;/
    )
      violations << "RLS is not enabled for public.#{table}"
    end
    unless sql.match?(
      /alter table public\.#{table} force row level security\s*;/
    )
      violations << "RLS is not forced for public.#{table}"
    end
  end

  fact_tables = %w[
    cached_products
    product_evidence
    score_snapshots
    methodology_versions
    parameters
    category_profiles
    profile_parameters
    source_mappings
    traceability_entities
    traceability_entity_identifiers
    traceability_relationships
  ]
  fact_tables.each do |table|
    write_grant = /
      grant\s+[^;]*(?:insert|update|delete)[^;]*
      on\s+table\s+public\.#{table}\s+
      to\s+(?:anon|authenticated)
    /x
    violations << "Client write grant found for #{table}" if sql.match?(
      write_grant
    )
  end

  required_markers = {
    "scan owner policy" => "(select auth.uid()) = user_id",
    "account deletion cascade" => "references auth.users(id) on delete cascade",
    "cache expiry policy" => "expires_at > timezone('utc', now())",
    "published evidence policy" => "published_at is not null",
    "evidence retrieval channel" => "retrieved_via_source_id",
    "published methodology policy" => "status = 'published'",
    "active source mapping policy" => "status = 'active'",
    "draft methodology version" => "'2.0-draft'",
    "OFF database license" => "'odbl-1.0'",
    "OFF attribution" => "'open food facts contributors'",
    "AGRIBALYSE database license" => "'etalab-2.0'",
    "AGRIBALYSE attribution" => "'source ademe, agribalyse v3.2'",
    "traceability assertion classes" => "'community_reported'",
    "score-eligible link constraint" =>
      "traceability_relationships_score_eligible_check",
    "relationship snapshot lineage" => "relationship_ids",
    "red-flag snapshot lineage" => "red_flag_evidence_ids",
    "product-scoped relationship context" => "context_entity_id",
    "relationship context constraint" =>
      "traceability_relationships_context_check",
    "GEPA declaration source" => "'gepa-product-declarations'",
  }
  required_markers.each do |name, marker|
    violations << "Missing #{name}" unless sql.include?(marker)
  end
end

source_register_path = File.join(
  repo_root,
  "docs",
  "project",
  "data",
  "source-register.yaml"
)
if File.exist?(source_register_path)
  register = YAML.safe_load(
    File.read(source_register_path),
    permitted_classes: [],
    permitted_symbols: [],
    aliases: false
  )
  sources = register.fetch("sources", [])
  off = sources.find { |source| source["id"] == "open-food-facts" }
  violations << "OFF source is not active in source register" unless (
    off && off["status"] == "active"
  )
  violations << "OFF ODbL license missing in source register" unless (
    off&.dig("license", "database") == "ODbL-1.0"
  )
  gepa = sources.find do |source|
    source["id"] == "gepa-product-declarations"
  end
  violations << "GEPA declaration source is not active" unless (
    gepa && gepa["status"] == "active"
  )
  violations << "GEPA declaration redistribution boundary missing" unless (
    gepa&.dig("license", "redistribution_allowed") == false &&
      gepa&.dig("license", "stored_content") ==
        "extracted_factual_assertions_and_provenance_only"
  )
else
  violations << "Missing ESG data source register"
end

dart_files = Dir.glob(
  File.join(repo_root, "esg_app", "lib", "**", "*.dart")
)
credential_pattern = /service[_-]?role|supabase_service_role_key/i
dart_files.each do |path|
  next unless File.read(path).match?(credential_pattern)

  violations << "Forbidden service-role reference in #{path.delete_prefix("#{repo_root}/")}"
end

if violations.empty?
  puts "Data architecture OK: #{migration_files.length} migration(s), RLS and license controls verified"
  exit 0
end

warn "Data architecture validation failed:"
violations.each { |violation| warn "- #{violation}" }
exit 1
