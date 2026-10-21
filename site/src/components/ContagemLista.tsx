import { Lista } from '../lib/lista';
import { usarLista } from './usarLista';

export default function ContagemLista() {
  const lista = usarLista(Lista.minha());
  return <span>Minha lista · {lista.itens.length}</span>;
}
