# Latest seller setup

Seller Gmail **000manoj0@gmail.com** reserve kar diya hai. Isi email se Aura account create aur verify karoge to seller access automatically milega. Manual 02-authorise-seller.sql run karna ab zaroori nahi. Seller panel: actual Netlify URL + `/seller/`, ya Account > Seller Studio. Public buyers ke liye Email signup, correct login URLs aur custom SMTP configure karna zaroori hai. Email confirmation ON rehni chahiye.

# Aura Frames ko live karne ka exact process

Buyer aur seller ek hi project ke do sections hain: buyer `/`, seller `/seller/`. Dono ko alag Netlify projects banane ki zaroorat nahi hai. Dono ek Supabase database use karenge.

## Ab tak kya ready hai

- Next.js + Supabase ke liye code convert ho gaya hai.
- Tumhara Aura Frame Supabase project connect karke Aura tables, permissions aur photo storage setup kar diya gaya hai.
- Purane basic `profiles` aur `products` tables ko change/delete nahi kiya.
- Naye catalogue mein ZERO products hain. Dono purane sample products apne-aap nahi aayenge.
- Website entry par Aura login hoga. Seller access alag protected hai.
- Abhi Netlify par deploy nahi hua. GitHub mein repository create/upload aur Netlify import baaki hain.

## 1. ZIP extract karo

`Aura-Frames-Netlify.zip` download karke right-click > Extract All karo. Andar `aura-frames` folder milega.

Is folder ke andar package.json, package-lock.json, netlify.toml aur app/components/public/lib/supabase folders honge. Ye saari cheezein GitHub par jayengi. ZIP file khud upload mat karna.

## 2. GitHub repository banao aur files upload karo

1. https://github.com/new kholo.
2. Repository name: `aura-frames`.
3. Visibility: **Private** rakh sakte ho. Netlify tumhari permission se private repository build kar sakta hai.
4. Add a README select kar do, phir Create repository dabao.
5. Repository mein **Add file > Upload files** kholo.
6. Extracted `aura-frames` folder ke ANDAR ki saari files/folders select karke upload area mein drag karo. Outer folder ko ek extra level par mat daalna.
7. **Commit changes** dabao.
8. Check: repository ke first page par `package.json`, `netlify.toml`, `app` aur `public` dikhne chahiye. `node_modules`, `.next` ya passwords upload nahi karne.

Agar seedha mujhse upload karwana hai, empty repository bana kar uska URL bhej do aur connected GitHub access mein woh repo available rakho. Main source upload continue kar sakta hoon.

## 3. Netlify ko GitHub se jodo

1. https://app.netlify.com/ kholo.
2. **Add new project > Import an existing project** select karo.
3. **GitHub** choose karo aur apni `aura-frames` repository ka access do.
4. `aura-frames` repo select karo; branch normally `main`.
5. Build settings:

| Field | Kya rakhna hai |
|---|---|
| Base directory | Khali — jab package.json repo root par ho |
| Framework | Next.js |
| Build command | npm run build |
| Publish directory | .next |
| Node version | 22 (netlify.toml mein already hai) |

## 4. Netlify mein Supabase configuration paste karo

Deploy se PEHLE Environment variables mein do values add karo. Agar import screen par option na mile to initial project create karke Project configuration > Environment variables kholo, phir redeploy karo.

`NETLIFY-ENV.txt` file kholo. Isme tumhare project ki EXACT do values likhi hain.

| Name field mein | Value field mein |
|---|---|
| NEXT_PUBLIC_SUPABASE_URL | NETLIFY-ENV.txt ka Project URL |
| NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY | NETLIFY-ENV.txt ki sb_publishable_... value |

Har name aur value alag field mein paste karna; name ke andar `=` nahi lagana. Quotes bhi nahi lagane. Scope **All scopes** ya **Builds and Functions**, Production ke liye select karo.

Database password, service_role, sb_secret ya GitHub token ki zaroorat nahi. App publishable key aur har user's login session se permissions enforce karta hai.

Ab **Deploy/Publish project** karo. Build successful hone par Netlify actual HTTPS website URL dega. Misal: `https://YOUR-SITE.netlify.app` — ye placeholder hai; tumhara exact URL Netlify se milega.

## 5. Supabase login ki URL settings

1. https://supabase.com/dashboard kholo > apna **Aura Frame** project.
2. **Authentication > URL Configuration** kholo.
3. **Site URL** mein Netlify ka actual website URL paste karo, misal `https://YOUR-SITE.netlify.app`. Is field mein GitHub ya Supabase URL nahi aayega.
4. **Redirect URLs** mein `https://YOUR-SITE.netlify.app/auth/callback` add karo. `YOUR-SITE` ko actual site name se replace karna.
5. Save karo. Custom domain baad mein lagao to dono settings mein us domain ka origin/callback bhi configure karo.
6. Email + Password signup enabled rakho aur **Confirm email ON** rakho. Dashboard mein ye setting Authentication ke Sign In / Providers ya Email section mein mil sakti hai.
7. Public customers ke confirmation/reset emails ke liye **custom SMTP** configure karo (Authentication > Email / SMTP settings). Provider se SMTP host, port, sender, username/password milenge; unhe sirf Supabase settings mein enter karo. Built-in sender public launch ke liye sufficient nahi hai.

Ab website login page par Create account > email/password se account banao. Confirmation link same browser mein kholo, phir sign in karo. Ye Aura account hai; ChatGPT login ki requirement Netlify version mein nahi hai.

Owner setup ke liye SMTP abhi ready nahi hai to Supabase **Authentication > Users > Add user > Create user** se apna account manually create kar sakte ho, apna password privately set karo, aur email confirmation option select karo. Public signup ke liye SMTP phir bhi configure karna hoga.

## 6. Apne account ko seller banao

Project setup ho gaya hai, lekin har naya account buyer hota hai. Seller access apne-aap nahi milta.

1. Pehle apna Aura user create aur verify karo.
2. ZIP ke `supabase/02-authorise-seller.sql` ko text editor mein kholo.
3. Sirf `'YOUR_SELLER_EMAIL'` ko apne Aura account ke exact email se replace karo. Single quotes rehne do.
4. Supabase > **SQL Editor > New query** kholo.
5. Is file ka poora updated SQL paste karke **Run** karo.
6. Website refresh karke actual Netlify URL ke end mein `/seller/` kholo. Ab Add product available hoga.

Password SQL mein paste nahi karna. Agar account verify nahi hua to script error degi; verification ke baad run karna.

`01-schema.sql` already isi project mein apply kar diya gaya hai. Dobara run karne ki zaroorat nahi. File future backup/new-project setup ke liye saath di gayi hai.

## 7. Product add karke buyer par check karo

1. Seller Studio > Products > **Add product**.
2. Actual name, category, shape, collection, description, materials, measurements bharo.
3. Photos upload karo: pehli photo buyer ki cover photo hogi. Baaki photos product page ki gallery mein khulengi. Make cover se order badal sakte ho.
4. Colours, sizes, actual price aur stock bharo. Reference/sample option OFF rakho for real products.
5. Publish select karke Save karo. Draft save kiya to buyer par nahi dikhega.
6. Buyer website doosre tab mein kholo. Refresh/focus karne par, ya visible tab mein lagbhag 15 seconds ke andar, published product dikhega.
7. Product update/unpublish bhi isi shared database se buyer par reflect hoga. Iske liye GitHub push ya Netlify redeploy nahi chahiye.

Homepage banner/model images design assets hain. Product listings se alag hain; seller mein product unpublish karne par banners nahi hatenge.

## 8. Order flow test karo, phir real COD enable karo

Checkout abhi TEST MODE mein hai. Sample address se order place karo > My orders mein dekho > seller Orders mein dekho > Packed > courier + tracking > Shipped > Delivered. Test order real delivery arrange nahi karta. Eligible test order Cancel karne par reserved stock restore hota hai.

Apne support contact, shipping/returns terms, delivery coverage aur prices final karne ke baad hi `supabase/03-enable-live-cod.sql` Supabase SQL Editor mein run karo. Isse real Cash on Delivery order mode enable hoga. Existing test orders test hi rahenge.

Current rule: ₹2,000 se kam subtotal par ₹99 delivery, otherwise free; AURA10 coupon 10% discount up to ₹500. Real launch se pehle in rules ko confirm/change karna. Tax invoice calculation included nahi hai. Courier booking aur COD collection tumhe apne delivery partner ke through arrange karni hogi.

UPI/card/Razorpay abhi connected nahi hai. Netlify ya Supabase account banana payment gateway connect nahi karta. Online payments ke liye merchant account + payment verification/webhooks ka separate integration chahiye.

## Agar problem aaye

- Build fail: Netlify > Deploys > failed deploy > build log. Error text share karo, secrets nahi.
- Login page configuration error: dono Netlify variables check karo aur redeploy karo.
- Confirmation email nahi aa rahi: SMTP, sender verification aur spam folder check karo.
- Seller access denied: exact verified Aura email ke liye 02-authorise-seller.sql run karo.
- Product nahi dikh raha: Published/active ho, correct Supabase project ho, buyer refresh karo.
- Buyer/seller purane ChatGPT preview par check mat karo; naye Netlify URLs par check karo. Old hosted preview ka database alag hai.
- GitHub mein code changes push karne se Netlify rebuild karega; product edits database se turant/focus refresh par aayenge.
