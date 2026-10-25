// Resultado da busca (/buscar?q=...): roda no navegador, porque o termo é livre.
import { useEffect, useState } from 'preact/hooks';
import { buscar, rpc } from '../lib/api';
import type { Oferta } from '../lib/formato';
import CardOferta from './CardOferta';

interface Rede { slug: string; nome: string }
interface Patrocinado { id: number; titulo: string; texto: string | null; link_url: string | null }
const POR_PAGINA = 30;

export default function Busca({ redes }: { redes: Rede[] }) {
  const termo = new URLSearchParams(location.search).get('q')?.trim() ?? '';
  const [rede, setRede] = useState<string>();
  const [menorPreco, setMenorPreco] = useState(false);
  const [ofertas, setOfertas] = useState<Oferta[]>([]);
  const [total, setTotal] = useState<number>();
  const [erro, setErro] = useState(false);
  const [carregando, setCarregando] = useState(false);
  const [patrocinados, setPatrocinados] = useState<Patrocinado[]>([]);

  async function carregar(de: number) {
    setCarregando(true);
    try {
      const r = await buscar(termo, { rede, menorPreco, de, quantos: POR_PAGINA });
      setOfertas((atuais) => (de === 0 ? r.ofertas : [...atuais, ...r.ofertas]));
      setTotal(r.total);
      setErro(false);
    } catch {
      setErro(true);
    }
    setCarregando(false);
  }

  useEffect(() => { if (termo) carregar(0); }, [rede, menorPreco]);
  useEffect(() => { if (termo) rpc<Patrocinado[]>('anuncios_da_busca', { termo }).then(setPatrocinados, () => {}); }, []);

  if (!termo) return (
    <section class="secao">
      <h1 style={{ fontSize: '22px' }}>Buscar ofertas</h1>
      <p class="suave" style={{ margin: 0 }}>Digite o que você procura na busca lá em cima ou comece por um destes:</p>
      <div class="atalhos">
        {['arroz', 'café', 'carne', 'leite', 'óleo'].map((t) => <a key={t} class="botao" href={`/buscar?q=${encodeURIComponent(t)}`}>{t}</a>)}
      </div>
    </section>
  );

  return (
    <section class="secao" aria-labelledby="titulo-busca">
      <div class="secao-topo">
        <h1 id="titulo-busca" style={{ fontSize: '22px' }}>
          {total == null ? `Buscando “${termo}”…` : `${total} ${total === 1 ? 'oferta' : 'ofertas'} para “${termo}”`}
        </h1>
        <label class="suave" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          Ordenar
          <select class="botao" value={menorPreco ? 'preco' : 'parecidas'} onChange={(e) => setMenorPreco(e.currentTarget.value === 'preco')}>
            <option value="parecidas">Mais parecidas</option>
            <option value="preco">Menor preço</option>
          </select>
        </label>
      </div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }} role="group" aria-label="Filtrar por mercado">
        {[{ slug: undefined, nome: 'Todos' }, ...redes].map((r) => (
          <button type="button" key={r.slug ?? 'todos'} class={`botao ${rede === r.slug ? 'botao-claro' : ''}`} aria-pressed={rede === r.slug} onClick={() => setRede(r.slug)}>{r.nome}</button>
        ))}
      </div>

      {patrocinados.map((p) => (
        <a key={p.id} class="anuncio anuncio-faixa" href={p.link_url ?? undefined} rel="sponsored noopener" target="_blank">
          <span class="selo">Patrocinado</span>
          <strong>{p.titulo}</strong>
          {p.texto && <span class="suave">{p.texto}</span>}
        </a>
      ))}

      {erro && <p class="tracejado">Não deu para buscar agora. Confira a internet e <button type="button" class="botao" onClick={() => carregar(0)}>tente de novo</button></p>}
      {total === 0 && !erro && <p class="tracejado">Nada nos encartes de hoje com “{termo}”. Tente outra palavra, como a marca ou só o produto.</p>}

      <div class="grade-ofertas">
        {ofertas.map((o) => <CardOferta key={o.id} o={o} />)}
      </div>
      {total != null && ofertas.length < total && (
        <button type="button" class="botao botao-grande" disabled={carregando} onClick={() => carregar(ofertas.length)}>
          {carregando ? 'Carregando…' : 'Ver mais'}
        </button>
      )}
    </section>
  );
}
