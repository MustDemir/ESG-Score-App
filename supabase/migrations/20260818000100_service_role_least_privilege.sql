-- Hosted Supabase grants service_role broad privileges on public objects by
-- default. ScanFair's writer contract is RPC-only: direct table access would
-- bypass validation, idempotency, publication and audit controls.

revoke all privileges on table public.data_sources from service_role;
revoke all privileges on table public.cached_products from service_role;
revoke all privileges on table public.product_evidence from service_role;
revoke all privileges on table public.score_snapshots from service_role;
revoke all privileges on table public.scans from service_role;
revoke all privileges on table public.methodology_versions from service_role;
revoke all privileges on table public.parameters from service_role;
revoke all privileges on table public.category_profiles from service_role;
revoke all privileges on table public.profile_parameters from service_role;
revoke all privileges on table public.source_mappings from service_role;
revoke all privileges on table public.traceability_entities from service_role;
revoke all privileges on table public.traceability_entity_identifiers
  from service_role;
revoke all privileges on table public.traceability_relationships
  from service_role;

revoke all privileges on all tables in schema private from service_role;
revoke all privileges on all sequences in schema public from service_role;
revoke all privileges on all sequences in schema private from service_role;

alter default privileges for role postgres in schema public
  revoke all privileges on tables from service_role;
alter default privileges for role postgres in schema private
  revoke all privileges on tables from service_role;
alter default privileges for role postgres in schema public
  revoke all privileges on sequences from service_role;
alter default privileges for role postgres in schema private
  revoke all privileges on sequences from service_role;

-- The trusted server identity may invoke only the bounded definer functions.
grant execute on function public.claim_writer_capacity(text, text, integer)
  to service_role;
grant execute on function public.record_writer_upstream_health(text, boolean)
  to service_role;
grant execute on function public.publish_off_product(
  text, text, text, text, jsonb, timestamptz, timestamptz, timestamptz, text
) to service_role;
grant execute on function public.record_writer_outcome(
  text, text, text, text, text, text, integer
) to service_role;
