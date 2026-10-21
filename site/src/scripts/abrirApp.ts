// Folha "Abrir no app / Continuar no navegador" (só no celular, uma vez por aparelho).
// Android: link de intent com o MESMO endereço → abre o app nesta página se ele estiver instalado;
// sem o app, o Android leva para a Play Store (browser_fallback_url).
// iPhone: com o app instalado o iOS já abre o link no app (Universal Links); aqui só oferecemos a App Store.
import { linkDoApp } from '../lib/app';

const folha = document.getElementById('abrir-app');
const VISTO = 'abrir_app_visto';

function visto() { try { return localStorage.getItem(VISTO) === '1'; } catch { return false; } }
function marcarVisto() { try { localStorage.setItem(VISTO, '1'); } catch { /* sem storage: aparece de novo, sem problema */ } }


if (folha && !visto()) {
  const link = linkDoApp(navigator.userAgent, location, folha.dataset);
  if (link) {
    const sim = document.getElementById('abrir-app-sim') as HTMLAnchorElement;
    sim.href = link;
    if (!/Android/i.test(navigator.userAgent)) sim.textContent = 'Baixar o app';
    const fechar = () => { folha.hidden = true; marcarVisto(); };
    sim.addEventListener('click', marcarVisto);
    document.getElementById('abrir-app-nao')!.addEventListener('click', fechar);
    document.addEventListener('keydown', (e) => { if (e.key === 'Escape' && !folha.hidden) fechar(); });
    folha.hidden = false;
    (document.getElementById('abrir-app-nao') as HTMLButtonElement).focus({ preventScroll: true });
  }
}
