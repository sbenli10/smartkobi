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

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  title text not null default 'Yeni Danışman Görüşmesi',
  topic text not null default 'general',
  last_message_preview text null,
  last_message_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.ai_conversations add column if not exists user_id uuid;
alter table public.ai_conversations add column if not exists business_id uuid;
alter table public.ai_conversations add column if not exists title text not null default 'Yeni Danışman Görüşmesi';
alter table public.ai_conversations add column if not exists topic text not null default 'general';
alter table public.ai_conversations add column if not exists last_message_preview text;
alter table public.ai_conversations add column if not exists last_message_at timestamptz;
alter table public.ai_conversations add column if not exists created_at timestamptz not null default now();
alter table public.ai_conversations add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ai_conversations_topic_check'
  ) then
    alter table public.ai_conversations
      add constraint ai_conversations_topic_check
      check (topic in ('general', 'finance', 'cashflow', 'customers', 'inventory', 'support', 'reports'));
  end if;
end $$;

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  business_id uuid null,
  role text not null,
  content text not null,
  message_type text not null default 'text',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.ai_messages add column if not exists user_id uuid;
alter table public.ai_messages add column if not exists conversation_id uuid;
alter table public.ai_messages add column if not exists business_id uuid;
alter table public.ai_messages add column if not exists role text not null default 'user';
alter table public.ai_messages add column if not exists content text not null default '';
alter table public.ai_messages add column if not exists message_type text not null default 'text';
alter table public.ai_messages add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.ai_messages add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'ai_messages_role_check'
  ) then
    alter table public.ai_messages
      add constraint ai_messages_role_check
      check (role in ('user', 'assistant', 'system'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'ai_messages_message_type_check'
  ) then
    alter table public.ai_messages
      add constraint ai_messages_message_type_check
      check (message_type in ('text', 'insight', 'warning', 'action'));
  end if;
end $$;

create table if not exists public.ai_business_context_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  context_date date not null default current_date,
  monthly_income numeric(14,2) not null default 0,
  monthly_expense numeric(14,2) not null default 0,
  net_profit numeric(14,2) not null default 0,
  pending_receivables numeric(14,2) not null default 0,
  overdue_receivables numeric(14,2) not null default 0,
  expected_cash_inflow_30d numeric(14,2) not null default 0,
  expected_cash_outflow_30d numeric(14,2) not null default 0,
  net_cash_30d numeric(14,2) not null default 0,
  cash_score integer not null default 50,
  critical_stock_count integer not null default 0,
  out_of_stock_count integer not null default 0,
  low_margin_product_count integer not null default 0,
  customer_risk_count integer not null default 0,
  top_risks jsonb not null default '[]'::jsonb,
  top_opportunities jsonb not null default '[]'::jsonb,
  summary_text text null,
  created_at timestamptz not null default now()
);

alter table public.ai_business_context_snapshots add column if not exists user_id uuid;
alter table public.ai_business_context_snapshots add column if not exists business_id uuid;
alter table public.ai_business_context_snapshots add column if not exists context_date date not null default current_date;
alter table public.ai_business_context_snapshots add column if not exists monthly_income numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists monthly_expense numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists net_profit numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists pending_receivables numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists overdue_receivables numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists expected_cash_inflow_30d numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists expected_cash_outflow_30d numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists net_cash_30d numeric(14,2) not null default 0;
alter table public.ai_business_context_snapshots add column if not exists cash_score integer not null default 50;
alter table public.ai_business_context_snapshots add column if not exists critical_stock_count integer not null default 0;
alter table public.ai_business_context_snapshots add column if not exists out_of_stock_count integer not null default 0;
alter table public.ai_business_context_snapshots add column if not exists low_margin_product_count integer not null default 0;
alter table public.ai_business_context_snapshots add column if not exists customer_risk_count integer not null default 0;
alter table public.ai_business_context_snapshots add column if not exists top_risks jsonb not null default '[]'::jsonb;
alter table public.ai_business_context_snapshots add column if not exists top_opportunities jsonb not null default '[]'::jsonb;
alter table public.ai_business_context_snapshots add column if not exists summary_text text;
alter table public.ai_business_context_snapshots add column if not exists created_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'ai_business_context_snapshots_cash_score_check'
  ) then
    alter table public.ai_business_context_snapshots
      add constraint ai_business_context_snapshots_cash_score_check
      check (cash_score >= 0 and cash_score <= 100);
  end if;
end $$;

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_business_context_snapshots enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_conversations' and policyname = 'ai_conversations_select_own'
  ) then
    create policy ai_conversations_select_own on public.ai_conversations
      for select using (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_conversations' and policyname = 'ai_conversations_insert_own'
  ) then
    create policy ai_conversations_insert_own on public.ai_conversations
      for insert with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_conversations' and policyname = 'ai_conversations_update_own'
  ) then
    create policy ai_conversations_update_own on public.ai_conversations
      for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_conversations' and policyname = 'ai_conversations_delete_own'
  ) then
    create policy ai_conversations_delete_own on public.ai_conversations
      for delete using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_messages' and policyname = 'ai_messages_select_own'
  ) then
    create policy ai_messages_select_own on public.ai_messages
      for select using (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_messages' and policyname = 'ai_messages_insert_own'
  ) then
    create policy ai_messages_insert_own on public.ai_messages
      for insert with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_messages' and policyname = 'ai_messages_update_own'
  ) then
    create policy ai_messages_update_own on public.ai_messages
      for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_messages' and policyname = 'ai_messages_delete_own'
  ) then
    create policy ai_messages_delete_own on public.ai_messages
      for delete using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_business_context_snapshots' and policyname = 'ai_context_select_own'
  ) then
    create policy ai_context_select_own on public.ai_business_context_snapshots
      for select using (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_business_context_snapshots' and policyname = 'ai_context_insert_own'
  ) then
    create policy ai_context_insert_own on public.ai_business_context_snapshots
      for insert with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_business_context_snapshots' and policyname = 'ai_context_update_own'
  ) then
    create policy ai_context_update_own on public.ai_business_context_snapshots
      for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'ai_business_context_snapshots' and policyname = 'ai_context_delete_own'
  ) then
    create policy ai_context_delete_own on public.ai_business_context_snapshots
      for delete using (auth.uid() = user_id);
  end if;
end $$;

drop trigger if exists set_ai_conversations_updated_at on public.ai_conversations;
create trigger set_ai_conversations_updated_at
before update on public.ai_conversations
for each row
execute function public.set_updated_at();

create index if not exists ai_conversations_user_id_idx
  on public.ai_conversations (user_id);
create index if not exists ai_conversations_topic_idx
  on public.ai_conversations (topic);
create index if not exists ai_conversations_last_message_at_idx
  on public.ai_conversations (last_message_at desc);
create index if not exists ai_messages_user_id_idx
  on public.ai_messages (user_id);
create index if not exists ai_messages_conversation_id_idx
  on public.ai_messages (conversation_id);
create index if not exists ai_messages_created_at_idx
  on public.ai_messages (created_at desc);
create index if not exists ai_messages_role_idx
  on public.ai_messages (role);
create index if not exists ai_context_user_id_idx
  on public.ai_business_context_snapshots (user_id);
create index if not exists ai_context_context_date_idx
  on public.ai_business_context_snapshots (context_date desc);
