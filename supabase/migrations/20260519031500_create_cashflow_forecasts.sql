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

create table if not exists public.cashflow_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  source_type text not null default 'manual' check (source_type in ('manual', 'transaction', 'customer', 'inventory', 'system')),
  source_id uuid null,
  entry_type text not null check (entry_type in ('inflow', 'outflow')),
  title text not null,
  category text null,
  amount numeric(14,2) not null check (amount >= 0),
  expected_date date not null default current_date,
  status text not null default 'expected' check (status in ('expected', 'confirmed', 'paid', 'overdue', 'cancelled')),
  recurrence text null check (recurrence is null or recurrence in ('none', 'weekly', 'monthly', 'quarterly', 'yearly')),
  confidence_level text not null default 'medium' check (confidence_level in ('low', 'medium', 'high')),
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cashflow_entries
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists source_type text not null default 'manual',
  add column if not exists source_id uuid,
  add column if not exists entry_type text,
  add column if not exists title text,
  add column if not exists category text,
  add column if not exists amount numeric(14,2) not null default 0,
  add column if not exists expected_date date not null default current_date,
  add column if not exists status text not null default 'expected',
  add column if not exists recurrence text,
  add column if not exists confidence_level text not null default 'medium',
  add column if not exists description text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.cashflow_scenarios (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  title text not null,
  scenario_type text not null default 'expense_check' check (scenario_type in ('expense_check', 'collection_delay', 'payment_plan', 'custom')),
  amount numeric(14,2) not null default 0 check (amount >= 0),
  scenario_date date not null default current_date,
  risk_level text not null default 'medium' check (risk_level in ('low', 'medium', 'high', 'critical')),
  result_summary text null,
  recommendation text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.cashflow_scenarios
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists title text,
  add column if not exists scenario_type text not null default 'expense_check',
  add column if not exists amount numeric(14,2) not null default 0,
  add column if not exists scenario_date date not null default current_date,
  add column if not exists risk_level text not null default 'medium',
  add column if not exists result_summary text,
  add column if not exists recommendation text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.cashflow_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  snapshot_date date not null default current_date,
  opening_balance numeric(14,2) not null default 0,
  expected_inflow_30d numeric(14,2) not null default 0,
  expected_outflow_30d numeric(14,2) not null default 0,
  net_cash_30d numeric(14,2) not null default 0,
  expected_inflow_60d numeric(14,2) not null default 0,
  expected_outflow_60d numeric(14,2) not null default 0,
  net_cash_60d numeric(14,2) not null default 0,
  cash_score integer not null default 50 check (cash_score >= 0 and cash_score <= 100),
  risk_level text not null default 'medium' check (risk_level in ('low', 'medium', 'high', 'critical')),
  ai_summary text null,
  created_at timestamptz not null default now()
);

alter table public.cashflow_snapshots
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists snapshot_date date not null default current_date,
  add column if not exists opening_balance numeric(14,2) not null default 0,
  add column if not exists expected_inflow_30d numeric(14,2) not null default 0,
  add column if not exists expected_outflow_30d numeric(14,2) not null default 0,
  add column if not exists net_cash_30d numeric(14,2) not null default 0,
  add column if not exists expected_inflow_60d numeric(14,2) not null default 0,
  add column if not exists expected_outflow_60d numeric(14,2) not null default 0,
  add column if not exists net_cash_60d numeric(14,2) not null default 0,
  add column if not exists cash_score integer not null default 50,
  add column if not exists risk_level text not null default 'medium',
  add column if not exists ai_summary text,
  add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_source_type_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_source_type_check
      check (source_type in ('manual', 'transaction', 'customer', 'inventory', 'system'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_entry_type_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_entry_type_check
      check (entry_type in ('inflow', 'outflow'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_status_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_status_check
      check (status in ('expected', 'confirmed', 'paid', 'overdue', 'cancelled'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_recurrence_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_recurrence_check
      check (recurrence is null or recurrence in ('none', 'weekly', 'monthly', 'quarterly', 'yearly'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_confidence_level_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_confidence_level_check
      check (confidence_level in ('low', 'medium', 'high'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_entries'
      and constraint_name = 'cashflow_entries_amount_check'
  ) then
    alter table public.cashflow_entries
      add constraint cashflow_entries_amount_check
      check (amount >= 0);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_scenarios'
      and constraint_name = 'cashflow_scenarios_scenario_type_check'
  ) then
    alter table public.cashflow_scenarios
      add constraint cashflow_scenarios_scenario_type_check
      check (scenario_type in ('expense_check', 'collection_delay', 'payment_plan', 'custom'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_scenarios'
      and constraint_name = 'cashflow_scenarios_risk_level_check'
  ) then
    alter table public.cashflow_scenarios
      add constraint cashflow_scenarios_risk_level_check
      check (risk_level in ('low', 'medium', 'high', 'critical'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_scenarios'
      and constraint_name = 'cashflow_scenarios_amount_check'
  ) then
    alter table public.cashflow_scenarios
      add constraint cashflow_scenarios_amount_check
      check (amount >= 0);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_snapshots'
      and constraint_name = 'cashflow_snapshots_cash_score_check'
  ) then
    alter table public.cashflow_snapshots
      add constraint cashflow_snapshots_cash_score_check
      check (cash_score >= 0 and cash_score <= 100);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'cashflow_snapshots'
      and constraint_name = 'cashflow_snapshots_risk_level_check'
  ) then
    alter table public.cashflow_snapshots
      add constraint cashflow_snapshots_risk_level_check
      check (risk_level in ('low', 'medium', 'high', 'critical'));
  end if;
end
$$;

alter table public.cashflow_entries enable row level security;
alter table public.cashflow_scenarios enable row level security;
alter table public.cashflow_snapshots enable row level security;

drop policy if exists "Users can view their own cashflow entries" on public.cashflow_entries;
drop policy if exists "Users can insert their own cashflow entries" on public.cashflow_entries;
drop policy if exists "Users can update their own cashflow entries" on public.cashflow_entries;
drop policy if exists "Users can delete their own cashflow entries" on public.cashflow_entries;

create policy "Users can view their own cashflow entries"
  on public.cashflow_entries
  for select
  using (auth.uid() = user_id);
create policy "Users can insert their own cashflow entries"
  on public.cashflow_entries
  for insert
  with check (auth.uid() = user_id);
create policy "Users can update their own cashflow entries"
  on public.cashflow_entries
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "Users can delete their own cashflow entries"
  on public.cashflow_entries
  for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can view their own cashflow scenarios" on public.cashflow_scenarios;
drop policy if exists "Users can insert their own cashflow scenarios" on public.cashflow_scenarios;
drop policy if exists "Users can update their own cashflow scenarios" on public.cashflow_scenarios;
drop policy if exists "Users can delete their own cashflow scenarios" on public.cashflow_scenarios;

create policy "Users can view their own cashflow scenarios"
  on public.cashflow_scenarios
  for select
  using (auth.uid() = user_id);
create policy "Users can insert their own cashflow scenarios"
  on public.cashflow_scenarios
  for insert
  with check (auth.uid() = user_id);
create policy "Users can update their own cashflow scenarios"
  on public.cashflow_scenarios
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "Users can delete their own cashflow scenarios"
  on public.cashflow_scenarios
  for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can view their own cashflow snapshots" on public.cashflow_snapshots;
drop policy if exists "Users can insert their own cashflow snapshots" on public.cashflow_snapshots;
drop policy if exists "Users can update their own cashflow snapshots" on public.cashflow_snapshots;
drop policy if exists "Users can delete their own cashflow snapshots" on public.cashflow_snapshots;

create policy "Users can view their own cashflow snapshots"
  on public.cashflow_snapshots
  for select
  using (auth.uid() = user_id);
create policy "Users can insert their own cashflow snapshots"
  on public.cashflow_snapshots
  for insert
  with check (auth.uid() = user_id);
create policy "Users can update their own cashflow snapshots"
  on public.cashflow_snapshots
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "Users can delete their own cashflow snapshots"
  on public.cashflow_snapshots
  for delete
  using (auth.uid() = user_id);

create index if not exists cashflow_entries_user_id_idx
  on public.cashflow_entries(user_id);
create index if not exists cashflow_entries_expected_date_idx
  on public.cashflow_entries(expected_date);
create index if not exists cashflow_entries_entry_type_idx
  on public.cashflow_entries(entry_type);
create index if not exists cashflow_entries_status_idx
  on public.cashflow_entries(status);
create index if not exists cashflow_entries_source_type_idx
  on public.cashflow_entries(source_type);

create index if not exists cashflow_scenarios_user_id_idx
  on public.cashflow_scenarios(user_id);
create index if not exists cashflow_scenarios_created_at_idx
  on public.cashflow_scenarios(created_at);
create index if not exists cashflow_scenarios_risk_level_idx
  on public.cashflow_scenarios(risk_level);

create index if not exists cashflow_snapshots_user_id_idx
  on public.cashflow_snapshots(user_id);
create index if not exists cashflow_snapshots_snapshot_date_idx
  on public.cashflow_snapshots(snapshot_date);
create index if not exists cashflow_snapshots_risk_level_idx
  on public.cashflow_snapshots(risk_level);

drop trigger if exists cashflow_entries_set_updated_at on public.cashflow_entries;
create trigger cashflow_entries_set_updated_at
before update on public.cashflow_entries
for each row
execute function public.set_updated_at();

drop trigger if exists cashflow_scenarios_set_updated_at on public.cashflow_scenarios;
create trigger cashflow_scenarios_set_updated_at
before update on public.cashflow_scenarios
for each row
execute function public.set_updated_at();
