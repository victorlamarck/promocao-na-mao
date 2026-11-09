// Card de uma oferta. Renderizado no build (páginas estáticas) e no navegador (busca).
// O "Adicionar" não tem lógica aqui: scripts/adicionar.ts atende todos os cards da página
// pelo data-oferta, assim o card não precisa virar componente interativo.
import { reais, diaMes, porUnidade, nomeDaOferta, mercado, atacado, condicaoCurta, iconeDaCategoria, type Oferta } from '../lib/formato';
import Vence from './Vence';
import { fotosUrl } from '../lib/config';

const mais = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14" /></svg>;
const menos = <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true"><path d="M5 12h14" /></svg>;

/** `principal`: na página da própria oferta, o nome é o título da página (h1) e não um link. */
export default function CardOferta({ o, mostrarMercado = true, principal = false }: { o: Oferta; mostrarMercado?: boolean; principal?: boolean }) {
  const nome = nomeDaOferta(o);
  const m = mercado(o.rede_slug);
  // na página da oferta (principal) a condição vai inteira, com o "vale na compra em quantidade" do atacado
  const condicao = principal ? o.condicao : condicaoCurta(o);
  // preço do clube mais baixo: ele vira o preço grande e a etiqueta mostra o preço sem o clube
  const clubeMenor = o.preco_clube != null && (o.preco == null || o.preco_clube < o.preco);
  const valor = clubeMenor ? o.preco_clube : o.preco;
  const clube = m.clube ?? 'clube';
  // o R$/kg do banco já é o do preço mais baixo (o mesmo do preço grande)
  const unidade = porUnidade(o.preco_referencia, o.unidade_referencia, valor);
  return (
    <article class={principal ? 'card card-principal' : 'card'} data-oferta={o.id} data-nome={nome}>
      {mostrarMercado && (
        <span class="card-mercado">
          <span class="ponto" style={{ background: m.cor }} />
          {o.rede_nome} · até {diaMes(o.validade_fim)}
        </span>
      )}
      {/* nas páginas estáticas, "hoje" é o dia do build (refeito todo dia às 03:05) */}
      <Vence fim={o.validade_fim} />
      {atacado(o) && <span class="etiqueta etiqueta-condicao">Preço de atacado</span>}
      {/* foto decorativa (alt vazio): o nome vem logo abaixo. Sem foto, o ícone da categoria com "Sem foto" */}
      {o.foto
        ? <img class="card-foto" src={`${fotosUrl}/${o.foto}`} alt="" loading="lazy" decoding="async" />
        : <span class="card-foto card-sem-foto" aria-hidden="true"><span>{iconeDaCategoria(o.categoria)}</span>Sem foto</span>}
      {principal ? <h1 class="card-titulo">{nome}</h1> : <h3><a class="card-link" href={`/oferta/${o.id}/`}>{nome}</a></h3>}
      <span class="card-preco">
        <span class="preco" style={valor == null ? { fontSize: '16px' } : undefined}>{valor == null ? 'Preço no mercado' : reais(valor)}</span>
        {unidade && <span class="suave">{unidade}</span>}
      </span>
      {o.preco_clube != null && (clubeMenor
        ? <span class="etiqueta">com {clube}{o.preco != null && ` · ${reais(o.preco)} sem`}</span>
        : <span class="etiqueta">{reais(o.preco_clube)} com {clube}</span>)}
      {o.preco_de != null && <span class="suave">Antes <s>{reais(o.preco_de)}</s></span>}
      {condicao && <span class="etiqueta etiqueta-condicao">{condicao}</span>}
      <div class="card-acao">
        <button type="button" class="add" aria-label={`Adicionar ${nome} à lista`}>{mais} Adicionar</button>
        <div class="contador" hidden>
          <button type="button" class="menos" aria-label={`Menos um ${nome}`}>{menos}</button>
          <span class="qtd" aria-live="polite">0</span>
          <button type="button" class="mais" aria-label={`Mais um ${nome}`}>{mais}</button>
        </div>
      </div>
    </article>
  );
}
