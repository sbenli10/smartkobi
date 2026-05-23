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

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  title text not null,
  message text not null,
  notification_type text not null check (
    notification_type in (
      'collection',
      'payment',
      'inventory',
      'cashflow',
      'document',
      'support',
      'report',
      'profile',
      'daily_plan',
      'system'
    )
  ),
  priority text not null default 'medium' check (
    priority in ('low', 'medium', 'high', 'critical')
  ),
  status text not null default 'unread' check (
    status in ('unread', 'read', 'archived', 'dismissed')
  ),
  source_module text null check (
    source_module is null or source_module in (
      'dashboard',
      'finance',
      'customers',
      'inventory',
      'cashflow',
      'documents',
      'support',
      'reports',
      'business_profile',
      'ai_advisor',
      'system'
    )
  ),
  source_id uuid null,
  action_route text null,
  action_label text null,
  metadata jsonb not null default '{}'::jsonb,
  scheduled_for timestamptz null,
  expires_at timestamptz null,
  read_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notifications add column if not exists user_id uuid;
alter table public.notifications add column if not exists business_id uuid;
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists message text;
alter table public.notifications add column if not exists notification_type text;
alter table public.notifications add column if not exists priority text not null default 'medium';
alter table public.notifications add column if not exists status text not null default 'unread';
alter table public.notifications add column if not exists source_module text;
alter table public.notifications add column if not exists source_id uuid;
alter table public.notifications add column if not exists action_route text;
alter table public.notifications add column if not exists action_label text;
alter table public.notifications add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.notifications add column if not exists scheduled_for timestamptz;
alter table public.notifications add column if not exists expires_at timestamptz;
alter table public.notifications add column if not exists read_at timestamptz;
alter table public.notifications add column if not exists created_at timestamptz not null default now();
alter table public.notifications add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'notifications_user_id_fkey'
  ) then
    alter table public.notifications
      add constraint notifications_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end
$$;

create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  collection_enabled boolean not null default true,
  payment_enabled boolean not null default true,
  inventory_enabled boolean not null default true,
  cashflow_enabled boolean not null default true,
  document_enabled boolean not null default true,
  support_enabled boolean not null default true,
  report_enabled boolean not null default true,
  profile_enabled boolean not null default true,
  daily_plan_enabled boolean not null default true,
  daily_plan_time text not null default '09:00',
  push_enabled boolean not null default false,
  email_enabled boolean not null default false,
  in_app_enabled boolean not null default true,
  quiet_hours_start text null,
  quiet_hours_end text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences add column if not exists user_id uuid;
alter table public.notification_preferences add column if not exists collection_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists payment_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists inventory_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists cashflow_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists document_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists support_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists report_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists profile_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists daily_plan_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists daily_plan_time text not null default '09:00';
alter table public.notification_preferences add column if not exists push_enabled boolean not null default false;
alter table public.notification_preferences add column if not exists email_enabled boolean not null default false;
alter table public.notification_preferences add column if not exists in_app_enabled boolean not null default true;
alter table public.notification_preferences add column if not exists quiet_hours_start text;
alter table public.notification_preferences add column if not exists quiet_hours_end text;
alter table public.notification_preferences add column if not exists created_at timestamptz not null default now();
alter table public.notification_preferences add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'notification_preferences_user_id_fkey'
  ) then
    alter table public.notification_preferences
      add constraint notification_preferences_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end
$$;

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'unknown' check (
    platform in ('android', 'ios', 'web', 'unknown')
  ),
  device_name text null,
  app_version text null,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens add column if not exists user_id uuid;
alter table public.device_tokens add column if not exists token text;
alter table public.device_tokens add column if not exists platform text not null default 'unknown';
alter table public.device_tokens add column if not exists device_name text;
alter table public.device_tokens add column if not exists app_version text;
alter table public.device_tokens add column if not exists is_active boolean not null default true;
alter table public.device_tokens add column if not exists last_seen_at timestamptz not null default now();
alter table public.device_tokens add column if not exists created_at timestamptz not null default now();
alter table public.device_tokens add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'device_tokens_user_id_fkey'
  ) then
    alter table public.device_tokens
      add constraint device_tokens_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end
$$;

create unique index if not exists notification_preferences_user_id_key
  on public.notification_preferences(user_id);

create unique index if not exists device_tokens_user_id_token_key
  on public.device_tokens(user_id, token);

create index if not exists notifications_user_id_idx
  on public.notifications(user_id);
create index if not exists notifications_status_idx
  on public.notifications(status);
create index if not exists notifications_type_idx
  on public.notifications(notification_type);
create index if not exists notifications_priority_idx
  on public.notifications(priority);
create index if not exists notifications_created_at_idx
  on public.notifications(created_at desc);
create index if not exists notifications_scheduled_for_idx
  on public.notifications(scheduled_for);
create index if not exists notifications_expires_at_idx
  on public.notifications(expires_at);

create index if not exists notification_preferences_user_id_idx
  on public.notification_preferences(user_id);

create index if not exists device_tokens_user_id_idx
  on public.device_tokens(user_id);
create index if not exists device_tokens_token_idx
  on public.device_tokens(token);
create index if not exists device_tokens_is_active_idx
  on public.device_tokens(is_active);

alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.device_tokens enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications
  for select
  using (user_id = auth.uid());

drop policy if exists "notifications_insert_own" on public.notifications;
create policy "notifications_insert_own"
  on public.notifications
  for insert
  with check (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "notifications_delete_own" on public.notifications;
create policy "notifications_delete_own"
  on public.notifications
  for delete
  using (user_id = auth.uid());

drop policy if exists "notification_preferences_select_own" on public.notification_preferences;
create policy "notification_preferences_select_own"
  on public.notification_preferences
  for select
  using (user_id = auth.uid());

drop policy if exists "notification_preferences_insert_own" on public.notification_preferences;
create policy "notification_preferences_insert_own"
  on public.notification_preferences
  for insert
  with check (user_id = auth.uid());

drop policy if exists "notification_preferences_update_own" on public.notification_preferences;
create policy "notification_preferences_update_own"
  on public.notification_preferences
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "notification_preferences_delete_own" on public.notification_preferences;
create policy "notification_preferences_delete_own"
  on public.notification_preferences
  for delete
  using (user_id = auth.uid());

drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own"
  on public.device_tokens
  for select
  using (user_id = auth.uid());

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own"
  on public.device_tokens
  for insert
  with check (user_id = auth.uid());

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own"
  on public.device_tokens
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own"
  on public.device_tokens
  for delete
  using (user_id = auth.uid());

drop trigger if exists notifications_set_updated_at on public.notifications;
create trigger notifications_set_updated_at
before update on public.notifications
for each row
execute function public.set_updated_at();

drop trigger if exists notification_preferences_set_updated_at on public.notification_preferences;
create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row
execute function public.set_updated_at();

drop trigger if exists device_tokens_set_updated_at on public.device_tokens;
create trigger device_tokens_set_updated_at
before update on public.device_tokens
for each row
execute function public.set_updated_at();
