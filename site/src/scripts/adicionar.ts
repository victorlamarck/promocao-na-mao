// Botões "Adicionar" / contador de todos os cards da página (CardOferta.tsx), com um
// ouvinte só no documento. Cards que aparecem depois (resultados da busca) também valem.
import { Lista } from '../lib/lista';

const lista = Lista.minha();

export function avisar(texto: string) {
  const el = document.getElementById('aviso');
  if (!el) return;
  el.textContent = texto;
  setTimeout(() => { if (el.textContent === texto) el.textContent = ''; }, 4000);
}

function atualizar(raiz: ParentNode = document) {
  raiz.querySelectorAll<HTMLElement>('[data-oferta]').forEach((card) => {
    const item = lista.itemDaOferta(Number(card.dataset.oferta));
    card.classList.toggle('na-lista', !!item);
    card.querySelector<HTMLElement>('.add')!.hidden = !!item;
    card.querySelector<HTMLElement>('.contador')!.hidden = !item;
    const qtd = card.querySelector('.qtd')!, valor = String(item?.quantidade ?? 0);
    if (qtd.textContent !== valor) qtd.textContent = valor; // só se mudou: senão o MutationObserver entra em laço
  });
}

document.addEventListener('click', async (e) => {
  const botao = (e.target as Element).closest<HTMLButtonElement>('.add, .mais, .menos');
  const card = botao?.closest<HTMLElement>('[data-oferta]');
  if (!botao || !card) return;
  const item = lista.itemDaOferta(Number(card.dataset.oferta));
  botao.disabled = true;
  try {
    if (botao.classList.contains('menos')) { if (item) await lista.quantidade(item, item.quantidade - 1); }
    else if (item) await lista.quantidade(item, item.quantidade + 1);
    else { await lista.adicionar(Number(card.dataset.oferta), card.dataset.nome!); avisar('Adicionado à sua lista'); }
  } catch {
    avisar('Não deu para salvar na lista. Confira a internet e tente de novo.');
  } finally {
    botao.disabled = false;
  }
});

lista.ouvir(() => atualizar());
new MutationObserver(() => atualizar()).observe(document.body, { childList: true, subtree: true });
lista.carregar();
