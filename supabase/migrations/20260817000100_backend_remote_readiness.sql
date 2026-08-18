-- Forward-only hardening after reconciling the linked Frankfurt development
-- schema. Historical migrations are already applied remotely and stay
-- immutable. Runtime activation, retention and rate-limit policy are separate
-- reviewed decisions.

-- Keep the persisted score-state contract aligned with formula v1.1.
alter table public.score_snapshots
  drop constraint if exists score_snapshots_score_state_check;

alter table public.score_snapshots
  add constraint score_snapshots_score_state_check
  check (
    score_state in (
      'full_score',
      'partial_score',
      'data_incomplete',
      'not_found'
    )
  );

-- Published evidence and snapshots may only be read through bounded,
-- barcode-scoped functions. Direct SELECT would expose enumerable endpoints.
revoke select on table public.product_evidence from anon, authenticated;
revoke select on table public.score_snapshots from anon, authenticated;

drop policy if exists "Published evidence is readable"
  on public.product_evidence;
drop policy if exists "Published score snapshots are readable"
  on public.score_snapshots;

create or replace function public.get_published_product_evidence(
  p_barcode text
)
returns table (
  id text,
  source_id text,
  retrieved_via_source_id text,
  source_record_id text,
  source_record_url text,
  source_field text,
  metric text,
  value_text text,
  numeric_value numeric,
  unit text,
  pillars text[],
  scope text,
  quality text,
  retrieved_at timestamptz,
  observed_at timestamptz,
  source_schema_version text,
  published_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    evidence.id,
    evidence.source_id,
    evidence.retrieved_via_source_id,
    evidence.source_record_id,
    evidence.source_record_url,
    evidence.source_field,
    evidence.metric,
    evidence.value_text,
    evidence.numeric_value,
    evidence.unit,
    evidence.pillars,
    evidence.scope,
    evidence.quality,
    evidence.retrieved_at,
    evidence.observed_at,
    evidence.source_schema_version,
    evidence.published_at
  from public.product_evidence as evidence
  join public.data_sources as source on source.id = evidence.source_id
  where p_barcode ~ '^[0-9]{8,14}$'
    and evidence.subject_type = 'product'
    and evidence.subject_id = p_barcode
    and evidence.published_at is not null
    and source.active
  order by evidence.published_at desc, evidence.id
  limit 100
$$;

revoke all on function public.get_published_product_evidence(text)
  from public;
grant execute on function public.get_published_product_evidence(text)
  to anon, authenticated;

create or replace function public.get_published_score_snapshot(
  p_barcode text,
  p_formula_version text default null
)
returns table (
  id uuid,
  barcode text,
  formula_version text,
  score_state text,
  environmental_score numeric,
  social_score numeric,
  governance_score numeric,
  total_score numeric,
  data_completeness numeric,
  data_confidence_score numeric,
  evidence_ids text[],
  relationship_ids uuid[],
  red_flag_evidence_ids text[],
  input_fingerprint text,
  calculated_at timestamptz,
  published_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    snapshot.id,
    snapshot.barcode,
    snapshot.formula_version,
    snapshot.score_state,
    snapshot.environmental_score,
    snapshot.social_score,
    snapshot.governance_score,
    snapshot.total_score,
    snapshot.data_completeness,
    snapshot.data_confidence_score,
    snapshot.evidence_ids,
    snapshot.relationship_ids,
    snapshot.red_flag_evidence_ids,
    snapshot.input_fingerprint,
    snapshot.calculated_at,
    snapshot.published_at
  from public.score_snapshots as snapshot
  where p_barcode ~ '^[0-9]{8,14}$'
    and snapshot.barcode = p_barcode
    and snapshot.published_at is not null
    and (
      p_formula_version is null
      or snapshot.formula_version = p_formula_version
    )
  order by snapshot.calculated_at desc, snapshot.id desc
  limit 1
$$;

revoke all on function public.get_published_score_snapshot(text, text)
  from public;
grant execute on function public.get_published_score_snapshot(text, text)
  to anon, authenticated;

comment on function public.get_published_product_evidence(text) is
  'Returns at most 100 published evidence rows for one valid product barcode.';
comment on function public.get_published_score_snapshot(text, text) is
  'Returns the latest published score for one valid barcode and optional formula version.';
