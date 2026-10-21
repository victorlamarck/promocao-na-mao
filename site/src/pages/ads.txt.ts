// /ads.txt: diz aos compradores de anúncio quem pode vender os espaços deste site (exigido pelo AdSense).
import { adsenseCliente } from '../lib/config';

export const GET = () =>
  new Response(adsenseCliente ? `google.com, ${adsenseCliente.replace(/^ca-/, '')}, DIRECT, f08c47fec0942fa0\n` : '', {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
