# Aura Frames — Netlify + Supabase

One standard Next.js application includes the buyer storefront at `/` and the protected seller studio at `/seller/`. It uses the same Supabase database, Auth and private Storage bucket. This is a separate deployment package; it does not change the existing ChatGPT-hosted preview.

Read **START-HERE-HINGLISH.md** for the full dashboard-by-dashboard setup.

## What is included

- Existing black/gold/cream buyer and seller designs, edited collection photos and the floral-frame model campaign.
- Independent Aura email/password signup, login, email confirmation, password reset and session refresh.
- Login required before visiting buyer or seller pages. Seller permission is checked in the API and PostgreSQL, not just hidden in the UI.
- Empty initial catalogue. No reference product is automatically seeded or shown as a fallback.
- Seller photo upload, up to six images, first image as cover, image reorder, publish/unpublish, prices, options and stock.
- Buyer catalogue refresh on focus and every 15 seconds while visible; no redeployment required for product edits.
- Server-calculated orders, atomic stock reservation, idempotent retries, buyer-specific order history and seller order status/tracking management.
- Test checkout by default. Optional live COD switch. Online card/UPI payments and courier booking are not integrated.

## Runtime

Node 22, Next.js 16, React 19, Supabase JS + SSR, Tailwind 4. Exact dependency versions are pinned in package.json and package-lock.json.

```sh
npm ci
cp .env.example .env.local
# Fill both values using NETLIFY-ENV.txt.
npm run dev
```

Local URL is normally http://localhost:3000. Run `npm run build` and `npm start` for production. Netlify auto-detects Next.js; netlify.toml supplies the build command and `.next` publish directory. Do not deploy this as a static HTML ZIP/drop upload: import the GitHub repository so Netlify builds the server routes.

## Database and security

`supabase/01-schema.sql` is the complete idempotent setup script. On 29 October 2026 it was already applied to project `iuqzvgxgfwtfasdrghdv` (Aura Frame). Existing `public.profiles` and `public.products` were retained unchanged. This app uses `aura_products`, `aura_orders`, `aura_seller_accounts`, `aura_store_settings`, a non-exposed `aura_private` schema, and private `product-photos` storage.

The app uses only the publishable key plus each user's signed-in session. It does not need a service-role key. Seller roles are controlled from SQL, never from user-editable profile metadata. All order writes use authenticated RPC wrappers and checked transactional implementations. Buyers cannot directly write orders or promote themselves to seller. Media URLs are served through authenticated API routes. Do not expose `aura_private` in Supabase's Data API settings.

## Auth setup

Enable Email + Password and keep email confirmation enabled. Set your actual Netlify HTTPS origin as Site URL and allow `https://YOUR-SITE.netlify.app/auth/callback`. Configure custom SMTP for public signup/confirmation/recovery emails; Supabase's built-in sender is intended for limited non-production use. The application never disables confirmation for convenience. Open PKCE confirmation/reset links in the same browser where you started the flow.

The approved seller Gmail is 000manoj0@gmail.com. The verified-email provisioning trigger in supabase/04-owner-email.sql is already applied to the connected project. Create and verify that Aura account to receive seller access automatically. Ordinary signups stay buyers. The older 02-authorise-seller.sql is only a manual alternative. For initial setup without SMTP, the owner may manually create their own user through Supabase Authentication > Users with email confirmation, then grant seller membership. The owner sets the password privately.

## Commerce readiness

Online deployment does not imply payment processing or delivery service. Test mode saves clearly labelled preview orders and reserves stock. Cancelling an eligible test order restores stock once. After final support contact, delivery/return terms, availability and test checkout are confirmed, run `supabase/03-enable-live-cod.sql` to allow real COD orders. Shipping logic is currently ₹99 below ₹2,000 and free at/above ₹2,000, with AURA10 providing 10% off capped at ₹500; confirm these rules before real sales. No tax invoice calculation is implemented. COD collection/settlement and courier booking must be handled separately. For Razorpay, a separate merchant integration with server verification and webhooks is required.

## Validation

- `npm run test:commerce`: 32 isolated Postgres/PGlite checks (RLS, seller restrictions, hidden drafts, covers, trusted pricing, idempotency, stock, cancellation, tracking, live/test mode, Storage policies). They never insert test records into hosted Supabase.
- `npm run check`: TypeScript.
- `npm run build`: standard Next.js production build.
- Hosted database structure, grants, empty catalogue/order/seller counts and security advisors verified after setup. Security advisors returned no findings.
- Actual email delivery, real signed-in seller/buyer flow on Netlify, gateway payments and fulfilment require the owner's deployment/account configuration; no claim is made that these have been completed.

## Deploy package

The ZIP contains repository source and public design assets; no node_modules, build output, passwords or private keys. Upload the CONTENTS of the extracted `aura-frames` folder to the repository root, so package.json and netlify.toml are directly at the top. Do not upload the ZIP file itself as the application source.
