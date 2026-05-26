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

alter table if exists public.inventory_items
  add column if not exists is_active boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

alter table if exists public.stock_movements
  add column if not exists updated_at timestamptz not null default now();

create index if not exists inventory_items_updated_at_idx
  on public.inventory_items(updated_at desc);

create index if not exists stock_movements_updated_at_idx
  on public.stock_movements(updated_at desc);

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
