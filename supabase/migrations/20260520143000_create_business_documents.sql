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

create table if not exists public.business_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_profile_id uuid null references public.business_profiles(id) on delete set null,
  business_id uuid null,
  title text not null,
  document_type text not null check (
    document_type in (
      'tax_certificate',
      'activity_certificate',
      'signature_circular',
      'sme_declaration',
      'capacity_report',
      'invoice',
      'receipt',
      'proforma_invoice',
      'quotation',
      'technical_specification',
      'iso_certificate',
      'tse_certificate',
      'ce_certificate',
      'export_document',
      'bank_document',
      'contract',
      'other'
    )
  ),
  category text not null default 'general' check (
    category in (
      'company',
      'finance',
      'support',
      'certification',
      'export',
      'technical',
      'contract',
      'general'
    )
  ),
  file_name text null,
  file_path text null,
  file_mime_type text null,
  file_size_bytes bigint null,
  status text not null default 'uploaded' check (
    status in (
      'missing',
      'uploaded',
      'needs_review',
      'approved',
      'expired',
      'will_expire',
      'rejected'
    )
  ),
  issue_date date null,
  expiry_date date null,
  issuer text null,
  reference_number text null,
  notes text null,
  tags text[] not null default '{}',
  source_module text null check (
    source_module is null or source_module in (
      'manual',
      'support_analysis',
      'business_profile',
      'ai_advisor',
      'system'
    )
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.business_documents add column if not exists user_id uuid;
alter table public.business_documents add column if not exists business_profile_id uuid;
alter table public.business_documents add column if not exists business_id uuid;
alter table public.business_documents add column if not exists title text;
alter table public.business_documents add column if not exists document_type text;
alter table public.business_documents add column if not exists category text default 'general';
alter table public.business_documents add column if not exists file_name text;
alter table public.business_documents add column if not exists file_path text;
alter table public.business_documents add column if not exists file_mime_type text;
alter table public.business_documents add column if not exists file_size_bytes bigint;
alter table public.business_documents add column if not exists status text default 'uploaded';
alter table public.business_documents add column if not exists issue_date date;
alter table public.business_documents add column if not exists expiry_date date;
alter table public.business_documents add column if not exists issuer text;
alter table public.business_documents add column if not exists reference_number text;
alter table public.business_documents add column if not exists notes text;
alter table public.business_documents add column if not exists tags text[] default '{}';
alter table public.business_documents add column if not exists source_module text;
alter table public.business_documents add column if not exists created_at timestamptz default now();
alter table public.business_documents add column if not exists updated_at timestamptz default now();

create table if not exists public.document_requirements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_profile_id uuid null references public.business_profiles(id) on delete set null,
  support_analysis_result_id uuid null references public.support_analysis_results(id) on delete set null,
  required_document_type text not null,
  title text not null,
  description text null,
  category text not null default 'support' check (
    category in (
      'company',
      'finance',
      'support',
      'certification',
      'export',
      'technical',
      'contract',
      'general'
    )
  ),
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'missing' check (
    status in ('missing', 'uploaded', 'not_required', 'completed')
  ),
  linked_document_id uuid null references public.business_documents(id) on delete set null,
  due_date date null,
  source_module text null check (
    source_module is null or source_module in (
      'support_analysis',
      'business_profile',
      'ai_advisor',
      'manual',
      'system'
    )
  ),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.document_requirements add column if not exists user_id uuid;
alter table public.document_requirements add column if not exists business_profile_id uuid;
alter table public.document_requirements add column if not exists support_analysis_result_id uuid;
alter table public.document_requirements add column if not exists required_document_type text;
alter table public.document_requirements add column if not exists title text;
alter table public.document_requirements add column if not exists description text;
alter table public.document_requirements add column if not exists category text default 'support';
alter table public.document_requirements add column if not exists priority text default 'medium';
alter table public.document_requirements add column if not exists status text default 'missing';
alter table public.document_requirements add column if not exists linked_document_id uuid;
alter table public.document_requirements add column if not exists due_date date;
alter table public.document_requirements add column if not exists source_module text;
alter table public.document_requirements add column if not exists created_at timestamptz default now();
alter table public.document_requirements add column if not exists updated_at timestamptz default now();

alter table public.business_documents enable row level security;
alter table public.document_requirements enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_documents' and policyname = 'business_documents_select_own'
  ) then
    create policy business_documents_select_own on public.business_documents
      for select using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_documents' and policyname = 'business_documents_insert_own'
  ) then
    create policy business_documents_insert_own on public.business_documents
      for insert with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_documents' and policyname = 'business_documents_update_own'
  ) then
    create policy business_documents_update_own on public.business_documents
      for update using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'business_documents' and policyname = 'business_documents_delete_own'
  ) then
    create policy business_documents_delete_own on public.business_documents
      for delete using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'document_requirements' and policyname = 'document_requirements_select_own'
  ) then
    create policy document_requirements_select_own on public.document_requirements
      for select using (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'document_requirements' and policyname = 'document_requirements_insert_own'
  ) then
    create policy document_requirements_insert_own on public.document_requirements
      for insert with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'document_requirements' and policyname = 'document_requirements_update_own'
  ) then
    create policy document_requirements_update_own on public.document_requirements
      for update using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'document_requirements' and policyname = 'document_requirements_delete_own'
  ) then
    create policy document_requirements_delete_own on public.document_requirements
      for delete using (user_id = auth.uid());
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'business_documents_set_updated_at'
  ) then
    create trigger business_documents_set_updated_at
      before update on public.business_documents
      for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'document_requirements_set_updated_at'
  ) then
    create trigger document_requirements_set_updated_at
      before update on public.document_requirements
      for each row execute function public.set_updated_at();
  end if;
end $$;

create index if not exists business_documents_user_id_idx
  on public.business_documents(user_id);
create index if not exists business_documents_business_profile_id_idx
  on public.business_documents(business_profile_id);
create index if not exists business_documents_document_type_idx
  on public.business_documents(document_type);
create index if not exists business_documents_category_idx
  on public.business_documents(category);
create index if not exists business_documents_status_idx
  on public.business_documents(status);
create index if not exists business_documents_expiry_date_idx
  on public.business_documents(expiry_date);
create index if not exists business_documents_created_at_idx
  on public.business_documents(created_at desc);

create index if not exists document_requirements_user_id_idx
  on public.document_requirements(user_id);
create index if not exists document_requirements_support_analysis_result_id_idx
  on public.document_requirements(support_analysis_result_id);
create index if not exists document_requirements_required_document_type_idx
  on public.document_requirements(required_document_type);
create index if not exists document_requirements_status_idx
  on public.document_requirements(status);
create index if not exists document_requirements_priority_idx
  on public.document_requirements(priority);

insert into storage.buckets (id, name, public)
select 'business-documents', 'business-documents', false
where not exists (
  select 1 from storage.buckets where id = 'business-documents'
);

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_documents_select_own'
  ) then
    create policy business_documents_select_own on storage.objects
      for select to authenticated
      using (
        bucket_id = 'business-documents'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_documents_insert_own'
  ) then
    create policy business_documents_insert_own on storage.objects
      for insert to authenticated
      with check (
        bucket_id = 'business-documents'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_documents_update_own'
  ) then
    create policy business_documents_update_own on storage.objects
      for update to authenticated
      using (
        bucket_id = 'business-documents'
        and (storage.foldername(name))[1] = auth.uid()::text
      )
      with check (
        bucket_id = 'business-documents'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'business_documents_delete_own'
  ) then
    create policy business_documents_delete_own on storage.objects
      for delete to authenticated
      using (
        bucket_id = 'business-documents'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end $$;
