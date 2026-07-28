-- Register AGRIBALYSE and preserve the delivery channel for upstream evidence.

alter table public.product_evidence
  add column if not exists retrieved_via_source_id text
  references public.data_sources(id) on delete restrict;

create index if not exists product_evidence_retrieval_source_idx
  on public.product_evidence (retrieved_via_source_id, retrieved_at desc);

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
  'agribalyse',
  'AGRIBALYSE',
  'https://entrepot.recherche.data.gouv.fr/dataset.xhtml?persistentId=doi:10.57745/XTENSJ',
  'https://doc.agribalyse.fr/documentation/utiliser-agribalyse/precautions-et-conditions-dusage',
  'Etalab-2.0',
  'Source ADEME, AGRIBALYSE v3.2',
  '3.2',
  date '2026-07-27'
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
