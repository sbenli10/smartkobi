create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_name text not null,
  legal_name text,
  tax_number text,
  tax_office text,
  business_type text,
  sector text,
  nace_code text,
  city text,
  district text,
  foundation_year integer,
  employee_count integer,
  annual_revenue_range text,
  monthly_expense_range text,
  does_manufacture boolean not null default false,
  does_export boolean not null default false,
  wants_export boolean not null default false,
  has_ecommerce boolean not null default false,
  has_physical_store boolean not null default false,
  needs_machinery boolean not null default false,
  needs_digitalization boolean not null default false,
  needs_certification boolean not null default false,
  needs_financing boolean not null default false,
  target_investment_amount numeric(14,2),
  main_products text,
  target_markets text,
  certifications text[] not null default '{}'::text[],
  profile_completion integer not null default 0,
  onboarding_completed boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.business_profiles add column if not exists user_id uuid references auth.users(id) on delete cascade;
alter table public.business_profiles add column if not exists business_name text;
alter table public.business_profiles add column if not exists legal_name text;
alter table public.business_profiles add column if not exists tax_number text;
alter table public.business_profiles add column if not exists tax_office text;
alter table public.business_profiles add column if not exists business_type text;
alter table public.business_profiles add column if not exists sector text;
alter table public.business_profiles add column if not exists nace_code text;
alter table public.business_profiles add column if not exists city text;
alter table public.business_profiles add column if not exists district text;
alter table public.business_profiles add column if not exists foundation_year integer;
alter table public.business_profiles add column if not exists employee_count integer;
alter table public.business_profiles add column if not exists annual_revenue_range text;
alter table public.business_profiles add column if not exists monthly_expense_range text;
alter table public.business_profiles add column if not exists does_manufacture boolean not null default false;
alter table public.business_profiles add column if not exists does_export boolean not null default false;
alter table public.business_profiles add column if not exists wants_export boolean not null default false;
alter table public.business_profiles add column if not exists has_ecommerce boolean not null default false;
alter table public.business_profiles add column if not exists has_physical_store boolean not null default false;
alter table public.business_profiles add column if not exists needs_machinery boolean not null default false;
alter table public.business_profiles add column if not exists needs_digitalization boolean not null default false;
alter table public.business_profiles add column if not exists needs_certification boolean not null default false;
alter table public.business_profiles add column if not exists needs_financing boolean not null default false;
alter table public.business_profiles add column if not exists target_investment_amount numeric(14,2);
alter table public.business_profiles add column if not exists main_products text;
alter table public.business_profiles add column if not exists target_markets text;
alter table public.business_profiles add column if not exists certifications text[] not null default '{}'::text[];
alter table public.business_profiles add column if not exists profile_completion integer not null default 0;
alter table public.business_profiles add column if not exists onboarding_completed boolean not null default false;
alter table public.business_profiles add column if not exists notes text;
alter table public.business_profiles add column if not exists created_at timestamptz not null default now();
alter table public.business_profiles add column if not exists updated_at timestamptz not null default now();

update public.business_profiles
set business_name = coalesce(nullif(trim(business_name), ''), 'İşletmem')
where business_name is null or trim(business_name) = '';

alter table public.business_profiles
  alter column business_name set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'business_profiles_business_type_check'
  ) then
    alter table public.business_profiles
      add constraint business_profiles_business_type_check
      check (
        business_type is null or business_type in (
          'sole_proprietorship',
          'limited',
          'joint_stock',
          'cooperative',
          'other'
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'business_profiles_employee_count_check'
  ) then
    alter table public.business_profiles
      add constraint business_profiles_employee_count_check
      check (employee_count is null or employee_count >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'business_profiles_annual_revenue_range_check'
  ) then
    alter table public.business_profiles
      add constraint business_profiles_annual_revenue_range_check
      check (
        annual_revenue_range is null or annual_revenue_range in (
          '0_1m',
          '1m_5m',
          '5m_10m',
          '10m_50m',
          '50m_plus',
          'unknown'
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'business_profiles_monthly_expense_range_check'
  ) then
    alter table public.business_profiles
      add constraint business_profiles_monthly_expense_range_check
      check (
        monthly_expense_range is null or monthly_expense_range in (
          '0_100k',
          '100k_500k',
          '500k_1m',
          '1m_5m',
          '5m_plus',
          'unknown'
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'business_profiles_profile_completion_check'
  ) then
    alter table public.business_profiles
      add constraint business_profiles_profile_completion_check
      check (profile_completion >= 0 and profile_completion <= 100);
  end if;
end $$;

alter table public.business_profiles enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_profiles'
      and policyname = 'business_profiles_select_own'
  ) then
    create policy business_profiles_select_own
      on public.business_profiles
      for select
      using (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_profiles'
      and policyname = 'business_profiles_insert_own'
  ) then
    create policy business_profiles_insert_own
      on public.business_profiles
      for insert
      with check (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_profiles'
      and policyname = 'business_profiles_update_own'
  ) then
    create policy business_profiles_update_own
      on public.business_profiles
      for update
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'business_profiles'
      and policyname = 'business_profiles_delete_own'
  ) then
    create policy business_profiles_delete_own
      on public.business_profiles
      for delete
      using (user_id = auth.uid());
  end if;
end $$;

create unique index if not exists business_profiles_user_id_idx
  on public.business_profiles(user_id);
create index if not exists business_profiles_sector_idx
  on public.business_profiles(sector);
create index if not exists business_profiles_nace_code_idx
  on public.business_profiles(nace_code);
create index if not exists business_profiles_city_idx
  on public.business_profiles(city);
create index if not exists business_profiles_profile_completion_idx
  on public.business_profiles(profile_completion);

drop trigger if exists business_profiles_set_updated_at on public.business_profiles;
create trigger business_profiles_set_updated_at
before update on public.business_profiles
for each row
execute function public.set_updated_at();
