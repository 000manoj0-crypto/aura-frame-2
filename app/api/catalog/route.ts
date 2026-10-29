import {user,product,json,error} from '../../../lib/server';
export async function GET(){try{const {db}=await user();const {data,error:e}=await db.from('aura_products').select('*').eq('active',true).order('updated_at',{ascending:false}).order('id');if(e)throw e;return json({products:(data||[]).map(product)})}catch(e){return error(e)}}
