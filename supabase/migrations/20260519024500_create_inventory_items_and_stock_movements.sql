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

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  business_id uuid null,
  name text not null,
  sku text null,
  barcode text null,
  category text null,
  unit text not null default 'adet',
  stock_quantity numeric(14,2) not null default 0,
  min_stock_level numeric(14,2) not null default 0,
  purchase_price numeric(14,2) not null default 0,
  sale_price numeric(14,2) not null default 0,
  supplier_name text null,
  supplier_phone text null,
  description text null,
  is_active boolean not null default true,
  last_movement_date date null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.inventory_items
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists name text,
  add column if not exists sku text,
  add column if not exists barcode text,
  add column if not exists category text,
  add column if not exists unit text not null default 'adet',
  add column if not exists stock_quantity numeric(14,2) not null default 0,
  add column if not exists min_stock_level numeric(14,2) not null default 0,
  add column if not exists purchase_price numeric(14,2) not null default 0,
  add column if not exists sale_price numeric(14,2) not null default 0,
  add column if not exists supplier_name text,
  add column if not exists supplier_phone text,
  add column if not exists description text,
  add column if not exists is_active boolean not null default true,
  add column if not exists last_movement_date date,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.inventory_items
set unit = coalesce(nullif(unit, ''), 'adet'),
    stock_quantity = coalesce(stock_quantity, 0),
    min_stock_level = coalesce(min_stock_level, 0),
    purchase_price = coalesce(purchase_price, 0),
    sale_price = coalesce(sale_price, 0),
    is_active = coalesce(is_active, true),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where unit is null
   or stock_quantity is null
   or min_stock_level is null
   or purchase_price is null
   or sale_price is null
   or is_active is null
   or created_at is null
   or updated_at is null;

create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete cascade,
  business_id uuid null,
  movement_type text not null check (movement_type in ('in', 'out', 'adjustment', 'return')),
  quantity numeric(14,2) not null check (quantity >= 0),
  unit_price numeric(14,2) null,
  movement_date date not null default current_date,
  reference_no text null,
  note text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.stock_movements
  add column if not exists user_id uuid references auth.users(id) on delete cascade,
  add column if not exists inventory_item_id uuid references public.inventory_items(id) on delete cascade,
  add column if not exists business_id uuid,
  add column if not exists movement_type text,
  add column if not exists quantity numeric(14,2) not null default 0,
  add column if not exists unit_price numeric(14,2),
  add column if not exists movement_date date not null default current_date,
  add column if not exists reference_no text,
  add column if not exists note text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.stock_movements
set quantity = coalesce(quantity, 0),
    movement_date = coalesce(movement_date, current_date),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now())
where quantity is null
   or movement_date is null
   or created_at is null
   or updated_at is null;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'stock_movements'
      and constraint_name = 'stock_movements_movement_type_check'
  ) then
    alter table public.stock_movements
      add constraint stock_movements_movement_type_check
      check (movement_type in ('in', 'out', 'adjustment', 'return'));
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'stock_movements'
      and constraint_name = 'stock_movements_quantity_check'
  ) then
    alter table public.stock_movements
      add constraint stock_movements_quantity_check
      check (quantity >= 0);
  end if;
end
$$;

alter table public.inventory_items enable row level security;
alter table public.stock_movements enable row level security;

drop policy if exists "Users can view their own inventory items" on public.inventory_items;
drop policy if exists "Users can insert their own inventory items" on public.inventory_items;
drop policy if exists "Users can update their own inventory items" on public.inventory_items;
drop policy if exists "Users can delete their own inventory items" on public.inventory_items;

create policy "Users can view their own inventory items"
  on public.inventory_items
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own inventory items"
  on public.inventory_items
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own inventory items"
  on public.inventory_items
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own inventory items"
  on public.inventory_items
  for delete
  using (auth.uid() = user_id);

drop policy if exists "Users can view their own stock movements" on public.stock_movements;
drop policy if exists "Users can insert their own stock movements" on public.stock_movements;
drop policy if exists "Users can update their own stock movements" on public.stock_movements;
drop policy if exists "Users can delete their own stock movements" on public.stock_movements;

create policy "Users can view their own stock movements"
  on public.stock_movements
  for select
  using (auth.uid() = user_id);

create policy "Users can insert their own stock movements"
  on public.stock_movements
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own stock movements"
  on public.stock_movements
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own stock movements"
  on public.stock_movements
  for delete
  using (auth.uid() = user_id);

create index if not exists inventory_items_user_id_idx
  on public.inventory_items(user_id);
create index if not exists inventory_items_name_idx
  on public.inventory_items(name);
create index if not exists inventory_items_sku_idx
  on public.inventory_items(sku);
create index if not exists inventory_items_barcode_idx
  on public.inventory_items(barcode);
create index if not exists inventory_items_category_idx
  on public.inventory_items(category);
create index if not exists inventory_items_stock_quantity_idx
  on public.inventory_items(stock_quantity);
create index if not exists inventory_items_min_stock_level_idx
  on public.inventory_items(min_stock_level);
create index if not exists inventory_items_is_active_idx
  on public.inventory_items(is_active);

create index if not exists stock_movements_user_id_idx
  on public.stock_movements(user_id);
create index if not exists stock_movements_inventory_item_id_idx
  on public.stock_movements(inventory_item_id);
create index if not exists stock_movements_movement_type_idx
  on public.stock_movements(movement_type);
create index if not exists stock_movements_movement_date_idx
  on public.stock_movements(movement_date);

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
before update on public.inventory_items
for each row
execute function public.set_updated_at();

drop trigger if exists stock_movements_set_updated_at on public.stock_movements;
create trigger stock_movements_set_updated_at
before update on public.stock_movements
for each row
execute function public.set_updated_at();
