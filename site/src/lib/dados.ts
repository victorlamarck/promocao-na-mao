// Dados lidos UMA vez no build (cache do módulo) e usados por todas as páginas geradas.
import { lerTudo } from './api';
import { conferirConfig, ehProd } from './config';
import type { Oferta } from './formato';

export interface Rede { id: number; nome: string; slug: string; ofertas: number; ate: string; lojas: number; atualizado_em: string }
export interface Loja { rede_id: number; nome: string | null; lat: number | null; lng: number | null }
export interface Anuncio {
  id: number; formato: string; titulo: string; texto: string | null; imagem_url: string | null; link_url: string | null; rede_id: number | null;
  /** cupom do comércio local (migration 30 do privado); vale até o fim do anúncio */
  cupom_codigo: string | null; cupom_regra: string | null; fim: string;
}

const colunas = 'id,texto_original,preco,preco_de,preco_clube,preco_por,condicao,secao,validade_fim,rede_id,rede_nome,rede_slug,itens,preco_referencia,unidade_referencia,foto,categoria';

let cache: Promise<{ ofertas: Oferta[]; redes: Rede[]; lojas: Loja[]; anuncios: Anuncio[]; inicio: number[] }> | undefined;

export function dados() {
  conferirConfig();
  cache ??= (async () => {
    const [ofertas, redes, lojas, anuncios, inicio] = await Promise.all([
      lerTudo<Oferta>('oferta_lista', `select=${colunas}&order=id.desc`),
      lerTudo<Rede>('rede_com_ofertas', 'select=*&order=nome'),
      lerTudo<Loja>('loja', 'select=rede_id,nome,lat,lng&lat=not.is.null'),
      lerTudo<Anuncio>('anuncio_vigente', 'select=id,formato,titulo,texto,imagem_url,link_url,rede_id,cupom_codigo,cupom_regra,fim&order=id'),
      // ids das ofertas da Início, no rodízio entre mercados do banco (a mesma ordem do app)
      lerTudo<{ id: number }>('oferta_inicio', 'select=id&order=ordem&limit=24'),
    ]);
    // Banco respondeu "200 []" (ex.: regra de leitura errada numa migration): melhor o build falhar e o site
    // de ontem continuar no ar do que publicar o prod sem nenhuma oferta.
    if (ehProd && (!ofertas.length || !redes.length)) throw new Error('banco sem ofertas ou sem mercados: build do prod parado');
    return { ofertas, redes, lojas, anuncios, inicio: inicio.map((o) => o.id) };
  })();
  return cache;
}
