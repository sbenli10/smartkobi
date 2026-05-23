create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.support_analysis_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_profile_id uuid null references public.business_profiles(id) on delete set null,
  business_id uuid null,
  analysis_title text not null default 'Destek Analizi',
  overall_score integer not null default 0,
  overall_status text not null default 'needs_profile',
  kosgeb_score integer not null default 0,
  tubitak_score integer not null default 0,
  export_support_score integer not null default 0,
  certification_support_score integer not null default 0,
  digitalization_support_score integer not null default 0,
  financing_support_score integer not null default 0,
  missing_profile_fields text[] not null default '{}',
  missing_documents text[] not null default '{}',
  recommended_actions text[] not null default '{}',
  risk_notes text[] not null default '{}',
  opportunity_notes text[] not null default '{}',
  summary text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.support_analysis_results
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_profile_id uuid references public.business_profiles(id) on delete set null,
  add column if not exists business_id uuid null,
  add column if not exists analysis_title text not null default 'Destek Analizi',
  add column if not exists overall_score integer not null default 0,
  add column if not exists overall_status text not null default 'needs_profile',
  add column if not exists kosgeb_score integer not null default 0,
  add column if not exists tubitak_score integer not null default 0,
  add column if not exists export_support_score integer not null default 0,
  add column if not exists certification_support_score integer not null default 0,
  add column if not exists digitalization_support_score integer not null default 0,
  add column if not exists financing_support_score integer not null default 0,
  add column if not exists missing_profile_fields text[] not null default '{}',
  add column if not exists missing_documents text[] not null default '{}',
  add column if not exists recommended_actions text[] not null default '{}',
  add column if not exists risk_notes text[] not null default '{}',
  add column if not exists opportunity_notes text[] not null default '{}',
  add column if not exists summary text null,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_overall_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_overall_score_check
      check (overall_score >= 0 and overall_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_overall_status_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_overall_status_check
      check (overall_status in ('high_potential', 'medium_potential', 'low_potential', 'needs_profile'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_kosgeb_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_kosgeb_score_check
      check (kosgeb_score >= 0 and kosgeb_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_tubitak_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_tubitak_score_check
      check (tubitak_score >= 0 and tubitak_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_export_support_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_export_support_score_check
      check (export_support_score >= 0 and export_support_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_certification_support_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_certification_support_score_check
      check (certification_support_score >= 0 and certification_support_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_digitalization_support_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_digitalization_support_score_check
      check (digitalization_support_score >= 0 and digitalization_support_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_analysis_results_financing_support_score_check'
  ) then
    alter table public.support_analysis_results
      add constraint support_analysis_results_financing_support_score_check
      check (financing_support_score >= 0 and financing_support_score <= 100);
  end if;
end $$;

create table if not exists public.support_opportunities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  analysis_result_id uuid null references public.support_analysis_results(id) on delete cascade,
  business_profile_id uuid null references public.business_profiles(id) on delete set null,
  support_type text not null,
  title text not null,
  description text null,
  eligibility_score integer not null default 0,
  eligibility_status text not null default 'needs_info',
  missing_requirements text[] not null default '{}',
  next_steps text[] not null default '{}',
  priority text not null default 'medium',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.support_opportunities
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists analysis_result_id uuid references public.support_analysis_results(id) on delete cascade,
  add column if not exists business_profile_id uuid references public.business_profiles(id) on delete set null,
  add column if not exists support_type text not null default 'other',
  add column if not exists title text not null default 'Destek Fırsatı',
  add column if not exists description text null,
  add column if not exists eligibility_score integer not null default 0,
  add column if not exists eligibility_status text not null default 'needs_info',
  add column if not exists missing_requirements text[] not null default '{}',
  add column if not exists next_steps text[] not null default '{}',
  add column if not exists priority text not null default 'medium',
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'support_opportunities_support_type_check'
  ) then
    alter table public.support_opportunities
      add constraint support_opportunities_support_type_check
      check (support_type in ('kosgeb', 'tubitak', 'export', 'certification', 'digitalization', 'financing', 'other'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_opportunities_eligibility_score_check'
  ) then
    alter table public.support_opportunities
      add constraint support_opportunities_eligibility_score_check
      check (eligibility_score >= 0 and eligibility_score <= 100);
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_opportunities_eligibility_status_check'
  ) then
    alter table public.support_opportunities
      add constraint support_opportunities_eligibility_status_check
      check (eligibility_status in ('high', 'medium', 'low', 'needs_info'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_opportunities_priority_check'
  ) then
    alter table public.support_opportunities
      add constraint support_opportunities_priority_check
      check (priority in ('low', 'medium', 'high'));
  end if;
end $$;

create table if not exists public.support_checklist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  analysis_result_id uuid null references public.support_analysis_results(id) on delete cascade,
  title text not null,
  description text null,
  category text not null default 'general',
  status text not null default 'pending',
  priority text not null default 'medium',
  due_date date null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.support_checklist_items
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists analysis_result_id uuid references public.support_analysis_results(id) on delete cascade,
  add column if not exists title text not null default 'Kontrol Öğesi',
  add column if not exists description text null,
  add column if not exists category text not null default 'general',
  add column if not exists status text not null default 'pending',
  add column if not exists priority text not null default 'medium',
  add column if not exists due_date date null,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'support_checklist_items_category_check'
  ) then
    alter table public.support_checklist_items
      add constraint support_checklist_items_category_check
      check (category in ('profile', 'document', 'finance', 'project', 'application', 'general'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_checklist_items_status_check'
  ) then
    alter table public.support_checklist_items
      add constraint support_checklist_items_status_check
      check (status in ('pending', 'completed', 'not_required'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'support_checklist_items_priority_check'
  ) then
    alter table public.support_checklist_items
      add constraint support_checklist_items_priority_check
      check (priority in ('low', 'medium', 'high'));
  end if;
end $$;

alter table public.support_analysis_results enable row level security;
alter table public.support_opportunities enable row level security;
alter table public.support_checklist_items enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_analysis_results'
      and policyname = 'support_analysis_results_select_own'
  ) then
    create policy support_analysis_results_select_own
      on public.support_analysis_results for select
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_analysis_results'
      and policyname = 'support_analysis_results_insert_own'
  ) then
    create policy support_analysis_results_insert_own
      on public.support_analysis_results for insert
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_analysis_results'
      and policyname = 'support_analysis_results_update_own'
  ) then
    create policy support_analysis_results_update_own
      on public.support_analysis_results for update
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_analysis_results'
      and policyname = 'support_analysis_results_delete_own'
  ) then
    create policy support_analysis_results_delete_own
      on public.support_analysis_results for delete
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_opportunities'
      and policyname = 'support_opportunities_select_own'
  ) then
    create policy support_opportunities_select_own
      on public.support_opportunities for select
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_opportunities'
      and policyname = 'support_opportunities_insert_own'
  ) then
    create policy support_opportunities_insert_own
      on public.support_opportunities for insert
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_opportunities'
      and policyname = 'support_opportunities_update_own'
  ) then
    create policy support_opportunities_update_own
      on public.support_opportunities for update
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_opportunities'
      and policyname = 'support_opportunities_delete_own'
  ) then
    create policy support_opportunities_delete_own
      on public.support_opportunities for delete
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_checklist_items'
      and policyname = 'support_checklist_items_select_own'
  ) then
    create policy support_checklist_items_select_own
      on public.support_checklist_items for select
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_checklist_items'
      and policyname = 'support_checklist_items_insert_own'
  ) then
    create policy support_checklist_items_insert_own
      on public.support_checklist_items for insert
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_checklist_items'
      and policyname = 'support_checklist_items_update_own'
  ) then
    create policy support_checklist_items_update_own
      on public.support_checklist_items for update
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'support_checklist_items'
      and policyname = 'support_checklist_items_delete_own'
  ) then
    create policy support_checklist_items_delete_own
      on public.support_checklist_items for delete
      using (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_trigger
    where tgname = 'set_support_analysis_results_updated_at'
  ) then
    create trigger set_support_analysis_results_updated_at
      before update on public.support_analysis_results
      for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger
    where tgname = 'set_support_opportunities_updated_at'
  ) then
    create trigger set_support_opportunities_updated_at
      before update on public.support_opportunities
      for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger
    where tgname = 'set_support_checklist_items_updated_at'
  ) then
    create trigger set_support_checklist_items_updated_at
      before update on public.support_checklist_items
      for each row execute function public.set_updated_at();
  end if;
end $$;

create index if not exists support_analysis_results_user_id_idx
  on public.support_analysis_results (user_id);
create index if not exists support_analysis_results_business_profile_id_idx
  on public.support_analysis_results (business_profile_id);
create index if not exists support_analysis_results_created_at_idx
  on public.support_analysis_results (created_at desc);
create index if not exists support_analysis_results_overall_status_idx
  on public.support_analysis_results (overall_status);

create index if not exists support_opportunities_user_id_idx
  on public.support_opportunities (user_id);
create index if not exists support_opportunities_analysis_result_id_idx
  on public.support_opportunities (analysis_result_id);
create index if not exists support_opportunities_support_type_idx
  on public.support_opportunities (support_type);
create index if not exists support_opportunities_priority_idx
  on public.support_opportunities (priority);

create index if not exists support_checklist_items_user_id_idx
  on public.support_checklist_items (user_id);
create index if not exists support_checklist_items_analysis_result_id_idx
  on public.support_checklist_items (analysis_result_id);
create index if not exists support_checklist_items_status_idx
  on public.support_checklist_items (status);
create index if not exists support_checklist_items_priority_idx
  on public.support_checklist_items (priority);
