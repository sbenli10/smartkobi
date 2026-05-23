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

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  name text not null,
  contact_name text null,
  phone text null,
  email text null,
  tax_number text null,
  address text null,
  city text null,
  opening_balance numeric(14,2) not null default 0,
  current_balance numeric(14,2) not null default 0,
  risk_level text not null default 'low' check (risk_level in ('low', 'medium', 'high')),
  payment_term_days integer not null default 30,
  last_transaction_date date null,
  next_collection_date date null,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.customers
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists name text,
  add column if not exists contact_name text,
  add column if not exists phone text,
  add column if not exists email text,
  add column if not exists tax_number text,
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists opening_balance numeric(14,2) not null default 0,
  add column if not exists current_balance numeric(14,2) not null default 0,
  add column if not exists risk_level text not null default 'low',
  add column if not exists payment_term_days integer not null default 30,
  add column if not exists last_transaction_date date,
  add column if not exists next_collection_date date,
  add column if not exists notes text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'customers'
      and column_name = 'last_interaction_at'
  ) then
    update public.customers
    set last_transaction_date = coalesce(last_transaction_date, last_interaction_at::date)
    where last_transaction_date is null;
  end if;
end
$$;

update public.customers
set current_balance = coalesce(current_balance, opening_balance, 0),
    opening_balance = coalesce(opening_balance, 0),
    risk_level = coalesce(nullif(risk_level, ''), 'low'),
    payment_term_days = coalesce(payment_term_days, 30),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where current_balance is null
   or opening_balance is null
   or risk_level is null
   or payment_term_days is null
   or created_at is null
   or updated_at is null;

create table if not exists public.customer_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  business_id uuid null,
  type text not null check (type in ('receivable', 'payment', 'debt', 'adjustment')),
  title text not null,
  amount numeric(14,2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  due_date date null,
  payment_status text not null default 'pending' check (payment_status in ('paid', 'pending', 'overdue')),
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.customer_transactions
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists customer_id uuid references public.customers(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists type text,
  add column if not exists title text,
  add column if not exists amount numeric(14,2) not null default 0,
  add column if not exists transaction_date date not null default current_date,
  add column if not exists due_date date,
  add column if not exists payment_status text not null default 'pending',
  add column if not exists description text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.customer_transactions
set payment_status = coalesce(nullif(payment_status, ''), 'pending'),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where payment_status is null
   or created_at is null
   or updated_at is null;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'customers'
      and constraint_name = 'customers_risk_level_check'
  ) then
    alter table public.customers
      add constraint customers_risk_level_check
      check (risk_level in ('low', 'medium', 'high'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'customer_transactions'
      and constraint_name = 'customer_transactions_type_check'
  ) then
    alter table public.customer_transactions
      add constraint customer_transactions_type_check
      check (type in ('receivable', 'payment', 'debt', 'adjustment'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'customer_transactions'
      and constraint_name = 'customer_transactions_payment_status_check'
  ) then
    alter table public.customer_transactions
      add constraint customer_transactions_payment_status_check
      check (payment_status in ('paid', 'pending', 'overdue'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'customer_transactions'
      and constraint_name = 'customer_transactions_amount_check'
  ) then
    alter table public.customer_transactions
      add constraint customer_transactions_amount_check
      check (amount >= 0);
  end if;
end
$$;

alter table public.customers enable row level security;
alter table public.customer_transactions enable row level security;

drop policy if exists "Users can view their own customers" on public.customers;
drop policy if exists "Users can insert their own customers" on public.customers;
drop policy if exists "Users can update their own customers" on public.customers;
drop policy if exists "Users can delete their own customers" on public.customers;

create policy "Users can view their own customers"
  on public.customers
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own customers"
  on public.customers
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own customers"
  on public.customers
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own customers"
  on public.customers
  for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can view their own customer transactions" on public.customer_transactions;
drop policy if exists "Users can insert their own customer transactions" on public.customer_transactions;
drop policy if exists "Users can update their own customer transactions" on public.customer_transactions;
drop policy if exists "Users can delete their own customer transactions" on public.customer_transactions;

create policy "Users can view their own customer transactions"
  on public.customer_transactions
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own customer transactions"
  on public.customer_transactions
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own customer transactions"
  on public.customer_transactions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own customer transactions"
  on public.customer_transactions
  for delete
  using (auth.uid() = user_id);

create index if not exists customers_user_id_idx
  on public.customers(user_id);

create index if not exists customers_name_idx
  on public.customers(name);

create index if not exists customers_risk_level_idx
  on public.customers(risk_level);

create index if not exists customers_current_balance_idx
  on public.customers(current_balance);

create index if not exists customers_next_collection_date_idx
  on public.customers(next_collection_date);

create index if not exists customer_transactions_user_id_idx
  on public.customer_transactions(user_id);

create index if not exists customer_transactions_customer_id_idx
  on public.customer_transactions(customer_id);

create index if not exists customer_transactions_due_date_idx
  on public.customer_transactions(due_date);

create index if not exists customer_transactions_payment_status_idx
  on public.customer_transactions(payment_status);

create index if not exists customer_transactions_type_idx
  on public.customer_transactions(type);

create index if not exists customer_transactions_transaction_date_idx
  on public.customer_transactions(transaction_date);

drop trigger if exists customers_set_updated_at on public.customers;
create trigger customers_set_updated_at
before update on public.customers
for each row
execute function public.set_updated_at();

drop trigger if exists customer_transactions_set_updated_at on public.customer_transactions;
create trigger customer_transactions_set_updated_at
before update on public.customer_transactions
for each row
execute function public.set_updated_at();
