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

create table if not exists public.business_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_profile_id uuid null references public.business_profiles(id) on delete set null,
  business_id uuid null,
  report_type text not null check (
    report_type in (
      'business_health',
      'financial_summary',
      'cashflow',
      'customer_risk',
      'inventory_risk',
      'support_eligibility',
      'document_gap',
      'daily_action_plan',
      'weekly_action_plan',
      'custom'
    )
  ),
  title text not null,
  period_label text null,
  period_start date null,
  period_end date null,
  status text not null default 'ready' check (
    status in ('draft', 'ready', 'generating', 'failed', 'archived')
  ),
  summary text null,
  key_findings text[] not null default '{}',
  risks text[] not null default '{}',
  opportunities text[] not null default '{}',
  recommended_actions text[] not null default '{}',
  report_data jsonb not null default '{}'::jsonb,
  pdf_file_path text null,
  pdf_file_name text null,
  generated_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.business_reports add column if not exists user_id uuid;
alter table public.business_reports add column if not exists business_profile_id uuid;
alter table public.business_reports add column if not exists business_id uuid;
alter table public.business_reports add column if not exists report_type text;
alter table public.business_reports add column if not exists title text;
alter table public.business_reports add column if not exists period_label text;
alter table public.business_reports add column if not exists period_start date;
alter table public.business_reports add column if not exists period_end date;
alter table public.business_reports add column if not exists status text default 'ready';
alter table public.business_reports add column if not exists summary text;
alter table public.business_reports add column if not exists key_findings text[] default '{}';
alter table public.business_reports add column if not exists risks text[] default '{}';
alter table public.business_reports add column if not exists opportunities text[] default '{}';
alter table public.business_reports add column if not exists recommended_actions text[] default '{}';
alter table public.business_reports add column if not exists report_data jsonb default '{}'::jsonb;
alter table public.business_reports add column if not exists pdf_file_path text;
alter table public.business_reports add column if not exists pdf_file_name text;
alter table public.business_reports add column if not exists generated_at timestamptz;
alter table public.business_reports add column if not exists created_at timestamptz default now();
alter table public.business_reports add column if not exists updated_at timestamptz default now();

create table if not exists public.report_sections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  report_id uuid not null references public.business_reports(id) on delete cascade,
  section_key text not null,
  title text not null,
  content text null,
  sort_order integer not null default 0,
  section_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.report_sections add column if not exists user_id uuid;
alter table public.report_sections add column if not exists report_id uuid;
alter table public.report_sections add column if not exists section_key text;
alter table public.report_sections add column if not exists title text;
alter table public.report_sections add column if not exists content text;
alter table public.report_sections add column if not exists sort_order integer default 0;
alter table public.report_sections add column if not exists section_data jsonb default '{}'::jsonb;
alter table public.report_sections add column if not exists created_at timestamptz default now();
alter table public.report_sections add column if not exists updated_at timestamptz default now();

create table if not exists public.report_export_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  report_id uuid null references public.business_reports(id) on delete set null,
  export_type text not null default 'pdf' check (
    export_type in ('pdf', 'preview', 'share')
  ),
  file_path text null,
  status text not null default 'success' check (
    status in ('success', 'failed')
  ),
  error_message text null,
  created_at timestamptz not null default now()
);

alter table public.report_export_logs add column if not exists user_id uuid;
alter table public.report_export_logs add column if not exists report_id uuid;
alter table public.report_export_logs add column if not exists export_type text default 'pdf';
alter table public.report_export_logs add column if not exists file_path text;
alter table public.report_export_logs add column if not exists status text default 'success';
alter table public.report_export_logs add column if not exists error_message text;
alter table public.report_export_logs add column if not exists created_at timestamptz default now();

alter table public.business_reports enable row level security;
alter table public.report_sections enable row level security;
alter table public.report_export_logs enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_reports' and policyname = 'business_reports_select_own'
  ) then
    create policy business_reports_select_own on public.business_reports
      for select using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_reports' and policyname = 'business_reports_insert_own'
  ) then
    create policy business_reports_insert_own on public.business_reports
      for insert with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_reports' and policyname = 'business_reports_update_own'
  ) then
    create policy business_reports_update_own on public.business_reports
      for update using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_reports' and policyname = 'business_reports_delete_own'
  ) then
    create policy business_reports_delete_own on public.business_reports
      for delete using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_sections' and policyname = 'report_sections_select_own'
  ) then
    create policy report_sections_select_own on public.report_sections
      for select using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_sections' and policyname = 'report_sections_insert_own'
  ) then
    create policy report_sections_insert_own on public.report_sections
      for insert with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_sections' and policyname = 'report_sections_update_own'
  ) then
    create policy report_sections_update_own on public.report_sections
      for update using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_sections' and policyname = 'report_sections_delete_own'
  ) then
    create policy report_sections_delete_own on public.report_sections
      for delete using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_export_logs' and policyname = 'report_export_logs_select_own'
  ) then
    create policy report_export_logs_select_own on public.report_export_logs
      for select using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_export_logs' and policyname = 'report_export_logs_insert_own'
  ) then
    create policy report_export_logs_insert_own on public.report_export_logs
      for insert with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_export_logs' and policyname = 'report_export_logs_update_own'
  ) then
    create policy report_export_logs_update_own on public.report_export_logs
      for update using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'report_export_logs' and policyname = 'report_export_logs_delete_own'
  ) then
    create policy report_export_logs_delete_own on public.report_export_logs
      for delete using (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'business_reports_set_updated_at'
  ) then
    create trigger business_reports_set_updated_at
      before update on public.business_reports
      for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'report_sections_set_updated_at'
  ) then
    create trigger report_sections_set_updated_at
      before update on public.report_sections
      for each row execute function public.set_updated_at();
  end if;
end $$;

create index if not exists business_reports_user_id_idx
  on public.business_reports(user_id);
create index if not exists business_reports_business_profile_id_idx
  on public.business_reports(business_profile_id);
create index if not exists business_reports_report_type_idx
  on public.business_reports(report_type);
create index if not exists business_reports_status_idx
  on public.business_reports(status);
create index if not exists business_reports_created_at_idx
  on public.business_reports(created_at desc);
create index if not exists business_reports_generated_at_idx
  on public.business_reports(generated_at desc);

create index if not exists report_sections_user_id_idx
  on public.report_sections(user_id);
create index if not exists report_sections_report_id_idx
  on public.report_sections(report_id);
create index if not exists report_sections_sort_order_idx
  on public.report_sections(sort_order);

create index if not exists report_export_logs_user_id_idx
  on public.report_export_logs(user_id);
create index if not exists report_export_logs_report_id_idx
  on public.report_export_logs(report_id);
create index if not exists report_export_logs_created_at_idx
  on public.report_export_logs(created_at desc);

insert into storage.buckets (id, name, public)
select 'business-reports', 'business-reports', false
where not exists (
  select 1 from storage.buckets where id = 'business-reports'
);

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_reports_select_own'
  ) then
    create policy business_reports_select_own on storage.objects
      for select to authenticated
      using (
        bucket_id = 'business-reports'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_reports_insert_own'
  ) then
    create policy business_reports_insert_own on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'business-reports'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_reports_update_own'
  ) then
    create policy business_reports_update_own on storage.objects
      for update to authenticated
      using (
        bucket_id = 'business-reports'
        and (storage.foldername(name))[1] = auth.uid()::text
      )
      with check (
        bucket_id = 'business-reports'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_reports_delete_own'
  ) then
    create policy business_reports_delete_own on storage.objects
      for delete to authenticated
      using (
        bucket_id = 'business-reports'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end $$;
