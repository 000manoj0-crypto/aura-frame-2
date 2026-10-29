-- OPTIONAL: enable real cash-on-delivery orders only after you are ready to fulfil them.
-- Configure final delivery/returns/contact information first and complete test checkout.
-- This does not connect UPI/cards/Razorpay, collect money or book a courier.
update public.aura_store_settings set live_cod=true where id=true;
-- To return to testing: update public.aura_store_settings set live_cod=false where id=true;
