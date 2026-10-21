// Configuração por variável de ambiente no build (nada de segredo: a chave do Supabase é a
// PÚBLICA, protegida pelo RLS). Sem variáveis = Supabase local, como o app em dev.
const env = import.meta.env;

export const ehProd = env.PUBLIC_FLAVOR === 'prod';
export const supabaseUrl: string = env.PUBLIC_SUPABASE_URL || 'http://127.0.0.1:54321';
export const supabaseChave: string = env.PUBLIC_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
/** AdSense (ca-pub-...): etiqueta de verificação no <head> e /ads.txt. Sem ele, nada do AdSense entra. */
export const adsenseCliente: string = env.PUBLIC_ADSENSE_CLIENT || '';
/** Lojas do app: sem o link, a folha "Abrir no app" não aparece naquela plataforma. */
export const lojaAndroid: string = env.PUBLIC_PLAY_STORE_URL || '';
export const lojaIos: string = env.PUBLIC_APP_STORE_URL || '';
/** Pacote Android do flavor (app/android/app/build.gradle.kts): o link de intent abre este app. */
export const pacoteAndroid = ehProd ? 'br.com.promocaonamao.app' : 'br.com.promocaonamao.app.dev';
export const contatoAnuncie: string =
  env.PUBLIC_CONTATO_ANUNCIE || (ehProd ? '' : 'https://wa.me/?text=Quero%20anunciar%20no%20Promo%C3%A7%C3%A3o%20na%20M%C3%A3o');

/** O prod não é gerado sem a config obrigatória (evita publicar apontando para o banco local). */
export function conferirConfig() {
  if (!ehProd) return;
  const faltando = Object.entries({
    PUBLIC_SUPABASE_URL: env.PUBLIC_SUPABASE_URL,
    PUBLIC_SUPABASE_PUBLISHABLE_KEY: env.PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    PUBLIC_CONTATO_ANUNCIE: env.PUBLIC_CONTATO_ANUNCIE,
  }).filter(([, v]) => !v).map(([k]) => k);
  if (faltando.length) throw new Error(`build do prod sem: ${faltando.join(', ')}`);
}
