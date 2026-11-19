// Em toda página: origem do anúncio (p e c), botões de baixar com essa origem, eventos e a faixa de cookies.
import { lerOrigem, linkDaLoja, origemAtual } from '../lib/origem';
import { consentimento, decidir, carregarPixel, evento } from '../lib/medir';

const o = origemAtual(location.search);
const origem = { publico: o?.p, criativo: o?.c };

if (lerOrigem(location.search)) evento('chegou_do_anuncio', origem);
if (consentimento() === 'sim') carregarPixel();

// Botões de baixar: <a data-loja="android|ios" data-onde="..." href="<link da loja>">
for (const a of document.querySelectorAll<HTMLAnchorElement>('a[data-loja]')) {
  const loja = a.dataset.loja as 'android' | 'ios';
  a.href = linkDaLoja(loja, a.href, o);
  a.addEventListener('click', () => evento('clique_baixar', { loja, onde: a.dataset.onde, ...origem }));
}

// Toque num recurso que só o app tem (o sino): <details data-recurso="sino">. O gráfico e a faixa contam pelo clique_baixar.
for (const d of document.querySelectorAll<HTMLDetailsElement>('details[data-recurso]')) {
  d.addEventListener('toggle', () => { if (d.open) evento('toque_recurso_app', { recurso: d.dataset.recurso, ...origem }); });
}

// Faixa de cookies: discreta, no rodapé, só depois que a folha "Abrir no app" sai da tela.
const faixa = document.getElementById('cookies');
if (faixa && consentimento() === null) {
  const folha = document.getElementById('abrir-app');
  const mostrar = () => { if (!folha || folha.hidden) { faixa.hidden = false; obs?.disconnect(); } };
  const obs = folha ? new MutationObserver(mostrar) : null;
  obs?.observe(folha!, { attributes: true, attributeFilter: ['hidden'] });
  mostrar();
  faixa.addEventListener('click', (e) => {
    const b = (e.target as HTMLElement).closest<HTMLButtonElement>('button[data-sim]');
    if (!b) return;
    decidir(b.dataset.sim === '1');
    faixa.hidden = true;
  });
}
