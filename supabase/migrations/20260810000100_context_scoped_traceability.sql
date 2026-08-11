-- Bind commodity-origin assertions to the product declaration they describe.
-- This prevents one product's coffee origin from leaking into another product.

alter table public.traceability_relationships
  add column if not exists context_entity_id text
  references public.traceability_entities(id) on delete restrict;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'traceability_relationships_context_check'
      and conrelid = 'public.traceability_relationships'::regclass
  ) then
    alter table public.traceability_relationships
      add constraint traceability_relationships_context_check
      check (
        (
          context_entity_id is null
          or (
            context_entity_id <> from_entity_id
            and context_entity_id <> to_entity_id
          )
        )
        and (
          not score_eligible
          or relationship_type <> 'commodity_has_origin'
          or context_entity_id is not null
        )
      );
  end if;
end
$$;

create or replace function public.enforce_traceability_context_type()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.context_entity_id is not null
    and not exists (
      select 1
      from public.traceability_entities
      where id = new.context_entity_id
        and entity_type = 'product'
    )
  then
    raise exception 'context_entity_id must reference a product entity'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_traceability_context_type
  on public.traceability_relationships;
create trigger enforce_traceability_context_type
before insert or update of context_entity_id, relationship_type, score_eligible
on public.traceability_relationships
for each row execute function public.enforce_traceability_context_type();

create index if not exists traceability_relationships_context_idx
  on public.traceability_relationships (
    context_entity_id,
    relationship_type,
    score_eligible
  );

drop policy if exists "Published traceability relationships are readable"
  on public.traceability_relationships;
create policy "Published traceability relationships are readable"
  on public.traceability_relationships
  for select
  to anon, authenticated
  using (
    published_at is not null
    and exists (
      select 1
      from public.traceability_entities
      where traceability_entities.id =
        traceability_relationships.from_entity_id
        and traceability_entities.published_at is not null
    )
    and exists (
      select 1
      from public.traceability_entities
      where traceability_entities.id =
        traceability_relationships.to_entity_id
        and traceability_entities.published_at is not null
    )
    and (
      context_entity_id is null
      or exists (
        select 1
        from public.traceability_entities
        where traceability_entities.id =
          traceability_relationships.context_entity_id
          and traceability_entities.published_at is not null
      )
    )
  );

insert into public.data_sources (
  id,
  display_name,
  source_url,
  terms_url,
  dataset_license,
  attribution,
  api_version,
  license_reviewed_on
)
values (
  'gepa-product-declarations',
  'GEPA Produktangaben',
  'https://www.gepa-shop.de',
  'https://www.gepa-shop.de/agb',
  'Proprietary-publication',
  'GEPA - The Fair Trade Company',
  'price-list-2025-04',
  date '2026-08-10'
)
on conflict (id) do update set
  display_name = excluded.display_name,
  source_url = excluded.source_url,
  terms_url = excluded.terms_url,
  dataset_license = excluded.dataset_license,
  attribution = excluded.attribution,
  api_version = excluded.api_version,
  license_reviewed_on = excluded.license_reviewed_on,
  updated_at = timezone('utc', now());
