import { useEffect, useState } from 'preact/hooks';
import type { Lista } from '../lib/lista';

/** Redesenha o componente sempre que a lista muda. */
export function usarLista(lista: Lista) {
  const [, setVersao] = useState(0);
  useEffect(() => lista.ouvir(() => setVersao((v) => v + 1)), [lista]);
  return lista;
}
