create extension if not exists pgcrypto;

create or replace function public.smartkobi_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

alter table if exists public.transactions
  add column if not exists user_id uuid,
  add column if not exists business_id uuid,
  add column if not exists title text,
  add column if not exists transaction_date date,
  add column if not exists payment_status text default 'paid',
  add column if not exists description text,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transactions'
      and column_name = 'date'
  ) then
    update public.transactions
    set transaction_date = coalesce(transaction_date, "date"::date, current_date)
    where transaction_date is null;
  end if;
end
$$;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transactions'
      and column_name = 'notes'
  ) then
    update public.transactions
    set description = coalesce(description, notes)
    where description is null;
  end if;
end
$$;

update public.transactions
set title = coalesce(
  nullif(title, ''),
  nullif(category, ''),
  case
    when type = 'income' then 'Gelir Kaydı'
    else 'Gider Kaydı'
  end
)
where title is null or title = '';

update public.transactions
set payment_status = coalesce(nullif(payment_status, ''), 'paid')
where payment_status is null or payment_status = '';

update public.transactions
set created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where created_at is null or updated_at is null;

do $$
begin
  if exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = 'user_business_roles'
  ) then
    update public.transactions t
    set user_id = ubr.user_id
    from (
      select distinct on (business_id) business_id, user_id
      from public.user_business_roles
      where business_id is not null
      order by business_id, user_id
    ) as ubr
    where t.business_id = ubr.business_id
      and t.user_id is null;
  end if;
end
$$;

alter table public.transactions
  alter column transaction_date set default current_date,
  alter column payment_status set default 'paid';

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'transactions'
      and constraint_name = 'transactions_type_check'
  ) then
    alter table public.transactions
      add constraint transactions_type_check
      check (type in ('income', 'expense'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'transactions'
      and constraint_name = 'transactions_payment_status_check'
  ) then
    alter table public.transactions
      add constraint transactions_payment_status_check
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
      and table_name = 'transactions'
      and constraint_name = 'transactions_amount_check'
  ) then
    alter table public.transactions
      add constraint transactions_amount_check
      check (amount >= 0);
  end if;
end
$$;

create index if not exists idx_transactions_user_id
  on public.transactions(user_id);

create index if not exists idx_transactions_transaction_date
  on public.transactions(transaction_date);

create index if not exists idx_transactions_type
  on public.transactions(type);

create index if not exists idx_transactions_payment_status
  on public.transactions(payment_status);

drop policy if exists "Users can view their own transactions" on public.transactions;
drop policy if exists "Users can insert their own transactions" on public.transactions;
drop policy if exists "Users can update their own transactions" on public.transactions;
drop policy if exists "Users can delete their own transactions" on public.transactions;

alter table public.transactions enable row level security;

create policy "Users can view their own transactions"
  on public.transactions
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own transactions"
  on public.transactions
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own transactions"
  on public.transactions
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own transactions"
  on public.transactions
  for delete
  using (auth.uid() = user_id);

drop trigger if exists transactions_set_updated_at on public.transactions;

create trigger transactions_set_updated_at
before update on public.transactions
for each row
execute function public.smartkobi_set_updated_at();
