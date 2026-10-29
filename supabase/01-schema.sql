-- Aura Frames: paste this entire file in Supabase > SQL Editor > New query > Run.
-- Starts with ZERO aura_products. No demo aura_orders, aura_products or seller accounts are seeded.
begin;
create schema if not exists aura_private;
revoke all on schema aura_private from public,anon;
grant usage on schema aura_private to authenticated;
create table if not exists public.aura_seller_accounts(user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.aura_products(
 id text primary key check(length(id) between 2 and 70),
 payload jsonb not null check(jsonb_typeof(payload)='object'),
 price integer not null check(price between 1 and 1000000),
 stock integer not null check(stock between 0 and 100000),
 active boolean not null default false,
 updated_at timestamptz not null default now()
);
create table if not exists public.aura_orders(
 id text primary key,
 user_id uuid not null references auth.users(id),
 request_key text not null check(length(request_key) between 16 and 80),
 payload jsonb not null,
 total integer not null check(total>=0),
 status text not null check(status in ('Confirmed','Packed','Shipped','Delivered','Cancelled')),
 created_at timestamptz not null default now(),
 unique(user_id,request_key)
);
create index if not exists orders_user_created on public.aura_orders(user_id,created_at desc);
create table if not exists public.aura_store_settings(id boolean primary key default true check(id),live_cod boolean not null default false);
insert into public.aura_store_settings(id,live_cod) values(true,false) on conflict(id) do nothing;
alter table public.aura_seller_accounts enable row level security;
alter table public.aura_products enable row level security;
alter table public.aura_orders enable row level security;
alter table public.aura_store_settings enable row level security;
drop policy if exists settings_deny_direct on public.aura_store_settings;
create policy settings_deny_direct on public.aura_store_settings for all to authenticated using(false) with check(false);
create or replace function aura_private.aura_is_seller() returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.aura_seller_accounts where user_id=(select auth.uid())); $$;
create or replace function aura_private.aura_store_mode() returns boolean language sql stable security definer set search_path='' as $$ select coalesce((select live_cod from public.aura_store_settings where id=true),false); $$;
create or replace function public.aura_is_seller() returns boolean language sql stable security invoker set search_path='' as $$select aura_private.aura_is_seller();$$;
create or replace function public.aura_store_mode() returns boolean language sql stable security invoker set search_path='' as $$select aura_private.aura_store_mode();$$;
drop policy if exists seller_self on public.aura_seller_accounts;
create policy seller_self on public.aura_seller_accounts for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists product_read on public.aura_products;
create policy product_read on public.aura_products for select to authenticated using(active or (select public.aura_is_seller()));
drop policy if exists product_insert on public.aura_products;
create policy product_insert on public.aura_products for insert to authenticated with check(public.aura_is_seller());
drop policy if exists product_update on public.aura_products;
create policy product_update on public.aura_products for update to authenticated using(public.aura_is_seller()) with check(public.aura_is_seller());
drop policy if exists order_read on public.aura_orders;
create policy order_read on public.aura_orders for select to authenticated using(user_id=(select auth.uid()) or (select public.aura_is_seller()));
revoke all on public.aura_seller_accounts,public.aura_products,public.aura_orders,public.aura_store_settings from anon,authenticated;
grant select on public.aura_seller_accounts,public.aura_orders to authenticated;
grant select,insert,update on public.aura_products to authenticated;
-- All order writes go through transactional functions below, even for sellers.
create or replace function aura_private.aura_place_order(p_key text,p_items jsonb,p_address jsonb,p_coupon text default '',p_payment text default 'cod') returns jsonb language plpgsql security definer set search_path='' as $$
declare
 uid uuid:=auth.uid(); existing public.aura_orders%rowtype; p public.aura_products%rowtype; x jsonb; a jsonb;
 items jsonb:='[]'; qty integer; needed integer; subtotal integer:=0; discount integer:=0; shipping integer; total integer;
 order_id text; result jsonb; address_key text; n integer; is_live boolean;
begin
 if uid is null then raise exception 'Please sign in.'; end if;
 if p_key is null or length(p_key) not between 16 and 80 then raise exception 'Invalid request key.'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text||':'||p_key,0));
 select * into existing from public.aura_orders where user_id=uid and request_key=p_key;
 if found then return existing.payload||jsonb_build_object('status',existing.status); end if;
 if p_payment is distinct from 'cod' then raise exception 'Online payments are not connected.'; end if;
 if p_items is null or jsonb_typeof(p_items)<>'array' then raise exception 'Invalid shopping bag.'; end if;
 if jsonb_array_length(p_items) not between 1 and 20 then raise exception 'Your bag must contain 1–20 variants.'; end if;
 if p_address is null or jsonb_typeof(p_address)<>'object' then raise exception 'Enter a delivery address.'; end if;
 foreach address_key in array array['name','phone','line','locality','city','state','pin'] loop
  n:=length(btrim(coalesce(p_address->>address_key,'')));
  if n<2 or n>250 then raise exception 'Invalid address field: %',address_key; end if;
 end loop;
 if length(btrim(p_address->>'name'))>80 or length(btrim(p_address->>'line'))<8 or length(btrim(p_address->>'locality'))>100 or length(btrim(p_address->>'city'))>70 or length(btrim(p_address->>'state'))>70 then raise exception 'Check your delivery address.'; end if;
 if (p_address->>'phone')!~'^[6-9][0-9]{9}$' or (p_address->>'pin')!~'^[1-9][0-9]{5}$' then raise exception 'Enter a valid Indian phone number and PIN.'; end if;
 -- Lock all referenced aura_products in consistent order before checking aggregate stock.
 perform 1 from public.aura_products where id in(select e->>'id' from jsonb_array_elements(p_items) e) order by id for update;
 for x in select value from jsonb_array_elements(p_items) loop
  if jsonb_typeof(x->'qty') is distinct from 'number' or (x->>'qty')!~'^[0-9]{1,2}$' then raise exception 'Invalid quantity.'; end if;
  qty:=(x->>'qty')::integer;
  if qty not between 1 and 10 then raise exception 'Quantity must be 1–10.'; end if;
  select * into p from public.aura_products where id=x->>'id' and active;
  if not found then raise exception 'A product is no longer available.'; end if;
  if not coalesce((p.payload->'colours') ? (x->>'colour'),false) or not coalesce((p.payload->'sizes') ? (x->>'size'),false) then raise exception 'Choose valid colour and size.'; end if;
  select sum((e->>'qty')::integer) into needed from jsonb_array_elements(p_items) e where e->>'id'=p.id;
  if needed>p.stock then raise exception 'Insufficient stock for %.',p.payload->>'name'; end if;
  items:=items||jsonb_build_array(jsonb_build_object('id',p.id,'name',p.payload->>'name','qty',qty,'price',p.price,'colour',x->>'colour','size',x->>'size','image',p.payload->'images'->>0,'sample',coalesce((p.payload->>'sample')::boolean,false)));
  subtotal:=subtotal+p.price*qty;
 end loop;
 discount:=case when p_coupon='AURA10' then least(500,floor(subtotal*0.1)::integer) else 0 end;
 shipping:=case when subtotal>=2000 then 0 else 99 end;total:=subtotal-discount+shipping;
 select live_cod into is_live from public.aura_store_settings where id=true;
 order_id:='AF-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,14));
 a:=jsonb_build_object('name',btrim(p_address->>'name'),'phone',p_address->>'phone','line',btrim(p_address->>'line'),'locality',btrim(p_address->>'locality'),'city',btrim(p_address->>'city'),'state',btrim(p_address->>'state'),'pin',p_address->>'pin');
 result:=jsonb_build_object('id',order_id,'createdAt',now(),'status','Confirmed','payment',case when is_live then 'Cash on delivery' else 'Cash on delivery · not collected' end,'preview',not coalesce(is_live,false),'address',a,'items',items,'subtotal',subtotal,'discount',discount,'coupon',case when p_coupon='AURA10' then 'AURA10' else '' end,'shipping',shipping,'total',total,'tracking','');
 for x in select jsonb_build_object('id',e->>'id','qty',sum((e->>'qty')::integer)) from jsonb_array_elements(p_items) e group by e->>'id' loop
  update public.aura_products set stock=stock-(x->>'qty')::integer where id=x->>'id';
 end loop;
 insert into public.aura_orders(id,user_id,request_key,payload,total,status) values(order_id,uid,p_key,result,total,'Confirmed');
 return result;
end; $$;
create or replace function aura_private.aura_update_order(p_id text,p_status text,p_tracking text default '') returns jsonb language plpgsql security definer set search_path='' as $$
declare o public.aura_orders%rowtype; result jsonb; x jsonb; tracking text:=left(btrim(coalesce(p_tracking,'')),160);
begin
 if not public.aura_is_seller() then raise exception 'Seller access required.'; end if;
 select * into o from public.aura_orders where id=p_id for update;
 if not found then raise exception 'Order not found.'; end if;
 if not ((o.status='Confirmed' and p_status in('Packed','Cancelled')) or(o.status='Packed' and p_status in('Shipped','Cancelled')) or(o.status='Shipped' and p_status='Delivered')) then raise exception 'This status change is not allowed.'; end if;
 if p_status='Shipped' and tracking='' then raise exception 'Add courier and tracking number before shipping.'; end if;
 if p_status='Cancelled' then
  perform 1 from public.aura_products where id in(select e->>'id' from jsonb_array_elements(o.payload->'items') e) order by id for update;
  for x in select value from jsonb_array_elements(o.payload->'items') loop update public.aura_products set stock=stock+(x->>'qty')::integer where id=x->>'id'; end loop;
 end if;
 result:=o.payload||jsonb_build_object('status',p_status,'tracking',case when tracking='' then coalesce(o.payload->>'tracking','') else tracking end);
 update public.aura_orders set status=p_status,payload=result where id=o.id;return result;
end; $$;
create or replace function public.aura_place_order(p_key text,p_items jsonb,p_address jsonb,p_coupon text default '',p_payment text default 'cod') returns jsonb language sql security invoker set search_path='' as $$select aura_private.aura_place_order(p_key,p_items,p_address,p_coupon,p_payment);$$;
create or replace function public.aura_update_order(p_id text,p_status text,p_tracking text default '') returns jsonb language sql security invoker set search_path='' as $$select aura_private.aura_update_order(p_id,p_status,p_tracking);$$;
revoke all on all functions in schema aura_private from public,anon,authenticated;
grant execute on function aura_private.aura_is_seller(),aura_private.aura_store_mode(),aura_private.aura_place_order(text,jsonb,jsonb,text,text),aura_private.aura_update_order(text,text,text) to authenticated;
revoke all on function public.aura_is_seller(),public.aura_store_mode(),public.aura_place_order(text,jsonb,jsonb,text,text),public.aura_update_order(text,text,text) from public,anon;
grant execute on function public.aura_is_seller(),public.aura_store_mode(),public.aura_place_order(text,jsonb,jsonb,text,text),public.aura_update_order(text,text,text) to authenticated;
-- Private photo bucket. Buyers view through the authenticated /api/media route.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('product-photos','product-photos',false,5242880,array['image/png','image/jpeg','image/webp']) on conflict(id) do nothing;
drop policy if exists aura_photo_read on storage.objects;
create policy aura_photo_read on storage.objects for select to authenticated using(bucket_id='product-photos');
drop policy if exists aura_photo_insert on storage.objects;
create policy aura_photo_insert on storage.objects for insert to authenticated with check(bucket_id='product-photos' and public.aura_is_seller());
commit;
