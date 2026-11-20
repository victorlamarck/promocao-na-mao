// De onde a pessoa veio (anúncio da Meta) e os links das lojas que levam essa origem até a instalação.
// O anúncio aponta para o site com ?p=<público>&c=<criativo> (ex.: ?p=jovens&c=A2). O site guarda isso e cada botão
// de baixar repassa: App Store com ct=ads-<p>-<c> (aparece no App Analytics da Apple) e Google Play com o referrer
// utm_campaign=ads-<p>, utm_content=<c> (o Firebase do app lê na 1ª abertura e liga a instalação à campanha).

export interface Origem { p: string; c: string | null }

const PUBLICOS = ['jovens', 'adultos', 'vizinhas'];
const CRIATIVO = /^[A-Z]\d{1,2}(v\d{1,2})?$/i; // A1, B6, A1v2

/** Lê p e c da URL; valor fora do esperado é ignorado (não vai para link nem para estatística). */
export function lerOrigem(search: string): Origem | null {
  const q = new URLSearchParams(search);
  const p = q.get('p')?.toLowerCase() ?? '';
  if (!PUBLICOS.includes(p)) return null;
  const c = q.get('c') ?? '';
  return { p, c: CRIATIVO.test(c) ? c.toUpperCase() : null };
}

/** Provider token da conta na App Store Connect: sem ele a Apple ignora o ct. Não é segredo. */
export const providerTokenApple = '129712555';

/** Página personalizada de cada público (t17): ppid da App Store e listing da Play. Enquanto a loja não aprova
 * (ou com o app fora da Play), ela abre a página padrão. "vizinhas" é a Campanha B: mesma página dos adultos. */
const PAGINA: Record<string, { ppid: string; listing: string }> = {
  jovens: { ppid: '91cbfa21-3c76-4263-a71c-49c8eecc9a05', listing: 'jovens' },
  adultos: { ppid: 'b47499fd-50f4-4df3-9102-bbadded019e4', listing: 'adultos' },
  vizinhas: { ppid: 'b47499fd-50f4-4df3-9102-bbadded019e4', listing: 'adultos' },
};

/** Link da loja com a origem. Sem anúncio, a origem é "site" (quem achou o site sozinho). */
export function linkDaLoja(loja: 'android' | 'ios', url: string, o: Origem | null): string {
  const u = new URL(url);
  const campanha = o ? `ads-${o.p}` : 'site';
  const pagina = o && PAGINA[o.p];
  if (pagina) u.searchParams.set(loja === 'ios' ? 'ppid' : 'listing', loja === 'ios' ? pagina.ppid : pagina.listing);
  if (loja === 'ios') {
    u.searchParams.set('pt', providerTokenApple);
    u.searchParams.set('ct', o?.c ? `${campanha}-${o.c}` : campanha);
    u.searchParams.set('mt', '8');
  } else {
    const ref = new URLSearchParams({ utm_source: o ? 'meta' : 'site', utm_medium: o ? 'paid' : 'referral', utm_campaign: campanha });
    if (o?.c) ref.set('utm_content', o.c);
    u.searchParams.set('referrer', ref.toString());
  }
  return u.toString();
}

const CHAVE = 'origem_anuncio';
const VALIDADE = 30 * 24 * 3600 * 1000; // a pessoa pode voltar dias depois e só então baixar

/** Guarda a origem da URL (se houver) e devolve a que vale agora. Sem storage, vale só a da URL. */
export function origemAtual(search: string, agora = Date.now()): Origem | null {
  const daUrl = lerOrigem(search);
  try {
    if (daUrl) { localStorage.setItem(CHAVE, JSON.stringify({ ...daUrl, em: agora })); return daUrl; }
    const s = JSON.parse(localStorage.getItem(CHAVE) ?? 'null');
    return s && agora - s.em < VALIDADE ? { p: s.p, c: s.c } : null;
  } catch {
    return daUrl;
  }
}
