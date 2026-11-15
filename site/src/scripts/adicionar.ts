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
  // todos os botões do card: "+" e "−" seguidos mandavam quantidades calculadas da mesma leitura
  const botoes = card.querySelectorAll<HTMLButtonElement>('.add, .mais, .menos');
  botoes.forEach((b) => (b.disabled = true));
  try {
    if (botao.classList.contains('menos')) { if (item) await lista.quantidade(item, item.quantidade - 1); }
    else if (item) await lista.quantidade(item, item.quantidade + 1);
    // 120 letras: limite do banco (o app corta igual, lista.dart)
    else { await lista.adicionar(Number(card.dataset.oferta), card.dataset.nome!.slice(0, 120)); avisar('Adicionado à sua lista'); }
  } catch (e) {
    // fetch sem rede dá TypeError; o resto é a recusa do banco ("a lista chegou ao limite de 300 itens"...)
    avisar(e instanceof TypeError ? 'Não deu para salvar na lista. Confira a internet e tente de novo.' : `Não deu para salvar: ${(e as Error).message}`);
  } finally {
    botoes.forEach((b) => (b.disabled = false));
  }
});

lista.ouvir(() => atualizar());
new MutationObserver(() => atualizar()).observe(document.body, { childList: true, subtree: true });
lista.carregar();
