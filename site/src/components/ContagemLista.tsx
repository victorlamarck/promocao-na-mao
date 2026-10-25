import { Lista } from '../lib/lista';
import { usarLista } from './usarLista';

export default function ContagemLista() {
  const lista = usarLista(Lista.minha());
  // no celular o rótulo some da tela (fica para o leitor de tela) e o botão vira ícone + número
  return <span><span class="rotulo-lista">Minha lista · </span>{lista.itens.length}</span>;
}
