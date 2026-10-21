// Selo "Vence hoje" / "Vence amanhã" / "Encarte venceu" (card e itens da lista).
import { avisoValidade } from '../lib/formato';

export default function Vence({ fim }: { fim: string | null }) {
  const aviso = fim && avisoValidade(fim);
  return aviso ? <span class={`etiqueta etiqueta-vence${aviso === 'Encarte venceu' ? ' venceu' : ''}`}>{aviso}</span> : null;
}
