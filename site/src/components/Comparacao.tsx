// "Em outros mercados" na página da oferta, como no app (oferta_page.dart): o mesmo produto em outros
// encartes e os parecidos (outra marca ou tamanho), pelo preço do kg/litro. Carrega no navegador
// (comparar_oferta, migration 17 do privado): o build não precisa de uma chamada por oferta.
import { useEffect, useState } from 'preact/hooks';
import { rpc } from '../lib/api';
import type { Oferta } from '../lib/formato';
import CardOferta from './CardOferta';

type Comparada = Oferta & { preco_comparado: number | null; unidade_comparada: string | null };

// O card mostra o preço por unidade comparável (ex.: pack de latas → R$/litro).
const paraCard = (o: Comparada): Oferta => ({
  ...o,
  preco_referencia: o.preco_comparado ?? o.preco_referencia,
  unidade_referencia: o.unidade_comparada ?? o.unidade_referencia,
});

const visiveis = 6;

export default function Comparacao({ id }: { id: number }) {
  const [r, setR] = useState<{ mesmo: Comparada[]; similares: Comparada[] } | null>(null);
  const [todos, setTodos] = useState(false);
  useEffect(() => { rpc<{ mesmo: Comparada[]; similares: Comparada[] }>('comparar_oferta', { oferta_id: id }).then(setR, () => {}); }, [id]);
  if (!r || (r.mesmo.length === 0 && r.similares.length === 0)) return null;
  const grade = (l: Comparada[]) => <div class="grade-ofertas">{l.map((o) => <CardOferta key={o.id} o={paraCard(o)} />)}</div>;
  return (
    <>
      {r.mesmo.length > 0 && (
        <section class="secao">
          <h2>O mesmo produto em outros encartes</h2>
          {grade(r.mesmo)}
        </section>
      )}
      {r.similares.length > 0 && (
        <section class="secao">
          <h2>Parecidos</h2>
          <p class="suave" style="margin: 0">Outra marca ou tamanho. Compare pelo preço do kg ou do litro.</p>
          {grade(todos ? r.similares : r.similares.slice(0, visiveis))}
          {!todos && r.similares.length > visiveis && (
            <button type="button" class="botao" onClick={() => setTodos(true)}>Ver mais {r.similares.length - visiveis} parecidos</button>
          )}
        </section>
      )}
    </>
  );
}
