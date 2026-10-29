import {supabase} from '../../../lib/supabase';
import {originCheck,json,error,ApiError} from '../../../lib/server';
export async function POST(req:Request){try{originCheck(req);const {error:e}=await (await supabase()).auth.signOut();if(e)throw new ApiError('Unable to sign out. Please try again.');return json({ok:true})}catch(e){return error(e)}}
