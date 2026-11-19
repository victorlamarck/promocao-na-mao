// Estatística do site: GA4 (o mesmo do app, no Firebase) e Pixel da Meta (anúncios).
// LGPD: sem aceite, o GA4 fica no "modo de consentimento" do Google (contagens sem cookie) e o Pixel nem carrega.
// O gtag começa no <head> (Base.astro), já com o consentimento salvo; aqui ficam o aceite, o Pixel e os eventos.
import { metaPixelId } from './config';

type Fn = (...a: unknown[]) => void;
interface Fbq { (...a: unknown[]): void; callMethod?: Fn; queue: unknown[]; push: unknown; loaded: boolean; version: string }
const w = window as unknown as { gtag?: Fn; fbq?: Fbq; _fbq?: unknown };
const CHAVE = 'consentimento';

export function consentimento(): 'sim' | 'nao' | null {
  try { const v = localStorage.getItem(CHAVE); return v === 'sim' || v === 'nao' ? v : null; } catch { return null; }
}

export function decidir(sim: boolean) {
  try { localStorage.setItem(CHAVE, sim ? 'sim' : 'nao'); } catch { /* sem storage: pergunta de novo na próxima página */ }
  const v = sim ? 'granted' : 'denied';
  w.gtag?.('consent', 'update', { analytics_storage: v, ad_storage: v, ad_user_data: v, ad_personalization: v });
  if (sim) carregarPixel();
}

/** O snippet oficial da Meta (fbevents.js), só depois do aceite. */
export function carregarPixel() {
  if (!metaPixelId || w.fbq) return;
  const fbq = ((...a: unknown[]) => { if (fbq.callMethod) fbq.callMethod(...a); else fbq.queue.push(a); }) as Fbq;
  fbq.push = fbq; fbq.loaded = true; fbq.version = '2.0'; fbq.queue = [];
  w.fbq = fbq; w._fbq = fbq;
  const s = document.createElement('script');
  s.async = true;
  s.src = 'https://connect.facebook.net/en_US/fbevents.js';
  document.head.append(s);
  fbq('init', metaPixelId);
  fbq('track', 'PageView');
}

/** Um evento para os dois: no GA4 com o nome dado; na Meta como evento personalizado. */
export function evento(nome: string, params: Record<string, string | null | undefined>) {
  const limpos = Object.fromEntries(Object.entries(params).filter(([, v]) => v));
  w.gtag?.('event', nome, limpos);
  w.fbq?.('trackCustom', nome, limpos);
}
