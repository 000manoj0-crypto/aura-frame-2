-- Run only AFTER you have created and verified your Aura account.
-- Replace ONLY the email below with your own seller email. Keep the quotes.
do $$
declare seller_email text := 'YOUR_SELLER_EMAIL'; seller_id uuid;
begin
 select id into seller_id from auth.users where lower(email)=lower(seller_email) and email_confirmed_at is not null;
 if seller_id is null then raise exception 'Create and verify this Aura account first, then use its exact email.'; end if;
 insert into public.aura_seller_accounts(user_id) values(seller_id) on conflict do nothing;
end $$;
-- Buyer signups never get seller access automatically.
