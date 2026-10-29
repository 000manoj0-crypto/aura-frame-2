-- Approved by the store owner: reserve seller access for this VERIFIED email.
-- Other signups remain buyers. Does not create an account or set its password.
begin;
create or replace function aura_private.provision_aura_owner()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if lower(coalesce(new.email,''))='000manoj0@gmail.com' and new.email_confirmed_at is not null then
    insert into public.aura_seller_accounts(user_id) values(new.id) on conflict do nothing;
  elsif tg_op='UPDATE' then
    if lower(coalesce(old.email,''))='000manoj0@gmail.com' then
      delete from public.aura_seller_accounts where user_id=new.id;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function aura_private.provision_aura_owner() from public,anon,authenticated;
drop trigger if exists on_aura_owner_verified on auth.users;
create trigger on_aura_owner_verified after insert or update of email,email_confirmed_at on auth.users
for each row execute function aura_private.provision_aura_owner();
insert into public.aura_seller_accounts(user_id)
select id from auth.users where lower(email)='000manoj0@gmail.com' and email_confirmed_at is not null
on conflict do nothing;
commit;
