import 'server-only';
import {supabase} from './supabase';
export class ApiError extends Error{status:number;constructor(message:string,status=400){super(message);this.status=status}}
export async function user(){const db=await supabase();const {data,error}=await db.auth.getUser();if(error||!data.user)throw new ApiError('Please sign in to your Aura account.',401);return {db,userId:data.user.id,email:data.user.email||'',displayName:data.user.user_metadata?.full_name||data.user.email||'Aura member'}}
export async function seller(){const u=await user();const {data,error}=await u.db.rpc('aura_is_seller');if(error||data!==true)throw new ApiError('Only the authorised Aura Frames seller can access this area.',403);return u}
export function json(data:unknown,status=200){return Response.json(data,{status,headers:{'Cache-Control':'private, no-store'}})}
export function error(e:unknown){return json({error:e instanceof ApiError?e.message:'The request could not be completed. Check your connection and store setup, then try again.'},e instanceof ApiError?e.status:500)}
export function originCheck(req:Request){const origin=req.headers.get('origin');if(!origin)return;let host='';try{host=new URL(origin).host}catch{throw new ApiError('Cross-origin request rejected.',403)}const allowed=[req.headers.get('x-forwarded-host'),req.headers.get('host'),new URL(req.url).host].filter(Boolean);if(!allowed.includes(host))throw new ApiError('Cross-origin request rejected.',403)}
export async function body(req:Request){const raw=await req.text();if(raw.length>100000)throw new ApiError('Request is too large.',413);try{return JSON.parse(raw)}catch{throw new ApiError('Invalid request data.')}}
export function product(row:any){return {...row.payload,id:row.id,price:row.price,stock:row.stock,active:row.active}}
export function databaseError(e:{code?:string,message:string}){if(['P0001','23514','22P02','22023'].includes(e.code||''))throw new ApiError(e.message,409);throw new Error('Database request failed')}
