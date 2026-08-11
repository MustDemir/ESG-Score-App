-- Separate database, content and image rights and keep the generic product
-- cache exclusively inside the Open Food Facts ODbL license partition.

alter table public.data_sources
  add column if not exists content_license text,
  add column if not exists image_license text,
  add column if not exists database_license_url text,
  add column if not exists content_license_url text,
  add column if not exists image_license_url text,
  add column if not exists license_partition text,
  add column if not exists raw_cache_policy text,
  add column if not exists public_redistribution_policy text;

update public.data_sources
set
  content_license = coalesce(content_license, dataset_license),
  database_license_url = coalesce(database_license_url, terms_url),
  content_license_url = coalesce(content_license_url, terms_url),
  license_partition = coalesce(license_partition, id),
  raw_cache_policy = coalesce(raw_cache_policy, 'forbidden'),
  public_redistribution_policy = coalesce(
    public_redistribution_policy,
    'prohibited'
  );

update public.data_sources
set
  content_license = 'DbCL-1.0',
  image_license = 'CC-BY-SA-3.0',
  database_license_url = 'https://opendatacommons.org/licenses/odbl/1-0/',
  content_license_url = 'https://opendatacommons.org/licenses/dbcl/1-0/',
  image_license_url = 'https://creativecommons.org/licenses/by-sa/3.0/',
  license_partition = 'off-odbl',
  raw_cache_policy = 'isolated_source_only',
  public_redistribution_policy = 'odbl_share_alike',
  license_reviewed_on = date '2026-08-11'
where id = 'open-food-facts';

update public.data_sources
set
  content_license = 'Etalab-2.0',
  image_license = null,
  database_license_url =
    'https://www.etalab.gouv.fr/wp-content/uploads/2018/11/open-licence.pdf',
  content_license_url =
    'https://www.etalab.gouv.fr/wp-content/uploads/2018/11/open-licence.pdf',
  image_license_url = null,
  license_partition = 'agribalyse-etalab',
  raw_cache_policy = 'dedicated_store_required',
  public_redistribution_policy = 'attribution_required',
  license_reviewed_on = date '2026-08-11'
where id = 'agribalyse';

update public.data_sources
set
  content_license = 'Proprietary-publication',
  image_license = null,
  database_license_url = 'https://www.gepa-shop.de/agb',
  content_license_url = 'https://www.gepa-shop.de/agb',
  image_license_url = null,
  license_partition = 'gepa-restricted',
  raw_cache_policy = 'forbidden',
  public_redistribution_policy = 'prohibited',
  license_reviewed_on = date '2026-08-11'
where id = 'gepa-product-declarations';

alter table public.data_sources
  alter column content_license set not null,
  alter column database_license_url set not null,
  alter column content_license_url set not null,
  alter column license_partition set not null,
  alter column raw_cache_policy set not null,
  alter column public_redistribution_policy set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'data_sources_license_partition_check'
      and conrelid = 'public.data_sources'::regclass
  ) then
    alter table public.data_sources
      add constraint data_sources_license_partition_check
      check (license_partition ~ '^[a-z0-9][a-z0-9-]*$');
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'data_sources_raw_cache_policy_check'
      and conrelid = 'public.data_sources'::regclass
  ) then
    alter table public.data_sources
      add constraint data_sources_raw_cache_policy_check
      check (
        raw_cache_policy in (
          'isolated_source_only',
          'dedicated_store_required',
          'forbidden'
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'data_sources_license_urls_check'
      and conrelid = 'public.data_sources'::regclass
  ) then
    alter table public.data_sources
      add constraint data_sources_license_urls_check
      check (
        database_license_url like 'https://%'
        and content_license_url like 'https://%'
        and (
          (image_license is null and image_license_url is null)
          or (
            image_license is not null
            and image_license_url like 'https://%'
          )
        )
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'data_sources_redistribution_policy_check'
      and conrelid = 'public.data_sources'::regclass
  ) then
    alter table public.data_sources
      add constraint data_sources_redistribution_policy_check
      check (
        public_redistribution_policy in (
          'odbl_share_alike',
          'attribution_required',
          'prohibited'
        )
      );
  end if;
end
$$;

create or replace function public.enforce_cached_product_license_boundary()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  source_partition text;
  source_cache_policy text;
begin
  select license_partition, raw_cache_policy
  into source_partition, source_cache_policy
  from public.data_sources
  where id = new.source_id;

  if not found then
    raise exception 'cached product source is not registered'
      using errcode = '23503';
  end if;

  if new.source_id <> 'open-food-facts'
    or source_partition <> 'off-odbl'
    or source_cache_policy <> 'isolated_source_only'
  then
    raise exception 'external product data requires a dedicated license store'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_cached_product_license_boundary
  on public.cached_products;
create trigger enforce_cached_product_license_boundary
before insert or update of source_id
on public.cached_products
for each row execute function public.enforce_cached_product_license_boundary();
