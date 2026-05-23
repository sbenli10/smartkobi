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

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  type text not null check (type in ('income', 'expense')),
  title text not null,
  category text not null,
  amount numeric(14,2) not null check (amount >= 0),
  transaction_date date not null default current_date,
  payment_status text not null default 'paid' check (payment_status in ('paid', 'pending', 'overdue')),
  description text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.transactions enable row level security;

create index if not exists idx_transactions_user_id
  on public.transactions(user_id);

create index if not exists idx_transactions_transaction_date
  on public.transactions(transaction_date);

create index if not exists idx_transactions_type
  on public.transactions(type);

create index if not exists idx_transactions_payment_status
  on public.transactions(payment_status);

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'transactions_set_updated_at'
  ) then
    create trigger transactions_set_updated_at
    before update on public.transactions
    for each row
    execute function public.smartkobi_set_updated_at();
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'transactions'
      and policyname = 'Users can view their own transactions'
  ) then
    create policy "Users can view their own transactions"
      on public.transactions
      for select
      using (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'transactions'
      and policyname = 'Users can insert their own transactions'
  ) then
    create policy "Users can insert their own transactions"
      on public.transactions
      for insert
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'transactions'
      and policyname = 'Users can update their own transactions'
  ) then
    create policy "Users can update their own transactions"
      on public.transactions
      for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'transactions'
      and policyname = 'Users can delete their own transactions'
  ) then
    create policy "Users can delete their own transactions"
      on public.transactions
      for delete
      using (auth.uid() = user_id);
  end if;
end
$$;
