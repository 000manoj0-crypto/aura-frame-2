import Buyer from '../../../components/Buyer';export default async function Page({params}){const {id}=await params;return <Buyer page="product" productId={id}/>}
