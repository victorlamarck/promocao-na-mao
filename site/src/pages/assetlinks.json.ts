// Copiado para /.well-known/assetlinks.json pelo `npm run build` (o Firebase Hosting responde `[]`
// nesse endereço se não houver arquivo publicado lá): o Android confere aqui que o
// site autoriza o app a abrir os links dele (App Links). ANDROID_SHA256 = digitais SHA-256 do
// certificado que assina o app, separadas por vírgula. Sem elas, a lista fica vazia (links abrem no navegador).
import { pacoteAndroid } from '../lib/config';

const digitais = (import.meta.env.ANDROID_SHA256 ?? '').split(',').map((d: string) => d.trim()).filter(Boolean);

export const GET = () =>
  new Response(
    JSON.stringify(digitais.length
      ? [{ relation: ['delegate_permission/common.handle_all_urls'], target: { namespace: 'android_app', package_name: pacoteAndroid, sha256_cert_fingerprints: digitais } }]
      : []),
    { headers: { 'Content-Type': 'application/json' } },
  );
