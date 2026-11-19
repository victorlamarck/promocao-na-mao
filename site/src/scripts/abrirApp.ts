// Folha "Abrir no app / Continuar no navegador" (só no celular, uma vez por aparelho).
// Android: link de intent com o MESMO endereço → abre o app nesta página se ele estiver instalado;
// sem o app, o Android leva para a Play Store (browser_fallback_url).
// iPhone: com o app instalado o iOS já abre o link no app (Universal Links); aqui só oferecemos a App Store.
import { faixaFechadaRecente, linkDoApp } from '../lib/app';
import { linkDaLoja, origemAtual } from '../lib/origem';
import { evento } from '../lib/medir';

const folha = document.getElementById('abrir-app');
const VISTO = 'abrir_app_visto';

function visto() { try { return localStorage.getItem(VISTO) === '1'; } catch { return false; } }
function marcarVisto() { try { localStorage.setItem(VISTO, '1'); } catch { /* sem storage: aparece de novo, sem problema */ } }


if (folha && !visto()) {
  // as lojas já com a origem do anúncio (t45): o Android cai na Play com o referrer, o iPhone na App Store com o ct
  const o = origemAtual(location.search), d = folha.dataset;
  const link = linkDoApp(navigator.userAgent, location, {
    ...d,
    android: d.android && linkDaLoja('android', d.android, o),
    ios: d.ios && linkDaLoja('ios', d.ios, o),
  });
  if (link) {
    const sim = document.getElementById('abrir-app-sim') as HTMLAnchorElement;
    sim.href = link;
    const android = /Android/i.test(navigator.userAgent);
    if (!android) sim.textContent = 'Baixar o app';
    const fechar = () => { folha.hidden = true; marcarVisto(); };
    sim.addEventListener('click', () => {
      marcarVisto();
      evento('clique_baixar', { loja: android ? 'android' : 'ios', onde: 'folha', publico: o?.p, criativo: o?.c });
    });
    document.getElementById('abrir-app-nao')!.addEventListener('click', fechar);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && !folha.hidden) fechar(); });
    folha.hidden = false;
    (document.getElementById('abrir-app-nao') as HTMLButtonElement).focus({ preventScroll: true });
  }
}

// Faixa "Baixe o app" no Android (no iPhone é a do próprio Safari, meta apple-itunes-app no Base.astro):
// discreta no topo, fechável (some por 30 dias) e nunca junto com a folha acima.
const faixa = document.getElementById('faixa-app');
const FECHADA = 'faixa_app_fechada';
function fechadaEm() { try { return localStorage.getItem(FECHADA); } catch { return null; } }
if (faixa && /Android/i.test(navigator.userAgent) && (!folha || folha.hidden) && !faixaFechadaRecente(fechadaEm(), Date.now())) {
  faixa.hidden = false;
  faixa.querySelector('.faixa-app-fechar')!.addEventListener('click', () => {
    faixa.hidden = true;
    try { localStorage.setItem(FECHADA, String(Date.now())); } catch { /* sem storage: volta na próxima página */ }
    evento('faixa_app_fechada', {});
  });
}
