import {NextResponse} from 'next/server';
import {supabase} from '../../../lib/supabase';
import {safeNext} from '../../../lib/navigation';
export async function GET(req:Request){const url=new URL(req.url),code=url.searchParams.get('code');if(code){const db=await supabase();const {error}=await db.auth.exchangeCodeForSession(code);if(!error)return NextResponse.redirect(new URL(safeNext(url.searchParams.get('next')),url.origin))}return NextResponse.redirect(new URL('/login?error=confirmation',url.origin))}
