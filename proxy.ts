import {createServerClient} from '@supabase/ssr';
import {NextResponse,type NextRequest} from 'next/server';
export async function proxy(request:NextRequest){
  let response=NextResponse.next({request});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if(!url||!key){if(!request.nextUrl.pathname.startsWith('/login')&&!request.nextUrl.pathname.startsWith('/auth/')&&!request.nextUrl.pathname.startsWith('/api/'))return NextResponse.redirect(new URL('/login',request.url));return response;}
  const client=createServerClient(url,key,{cookieOptions:{httpOnly:true,secure:process.env.NODE_ENV==='production',sameSite:'lax'},cookies:{getAll:()=>request.cookies.getAll(),setAll(values){for(const {name,value} of values)request.cookies.set(name,value);response=NextResponse.next({request});for(const {name,value,options} of values)response.cookies.set(name,value,options)}}});
  const {data:{user}}=await client.auth.getUser();
  const path=request.nextUrl.pathname;
  const publicPath=path==='/login'||path.startsWith('/auth/')||path==='/logout'||path.startsWith('/api/');
  if(!user&&!publicPath){const target=request.nextUrl.clone();target.pathname='/login';target.search='';target.searchParams.set('next',path+request.nextUrl.search);const redirect=NextResponse.redirect(target);for(const c of response.cookies.getAll())redirect.cookies.set(c);redirect.headers.set('Cache-Control','private, no-store');return redirect;}
  response.headers.set('Cache-Control','private, no-store');return response;
}
export const config={matcher:['/((?!_next/static|_next/image|assets/|favicon.ico|robots.txt).*)']};
