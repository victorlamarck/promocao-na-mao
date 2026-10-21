// Dados lidos UMA vez no build (cache do módulo) e usados por todas as páginas geradas.
import { lerTudo } from './api';
import { conferirConfig } from './config';
import type { Oferta } from './formato';

export interface Rede { id: number; nome: string; slug: string; ofertas: number; ate: string; lojas: number; atualizado_em: string }
export interface Loja { rede_id: number; nome: string | null; lat: number | null; lng: number | null }
export interface Anuncio { id: number; formato: string; titulo: string; texto: string | null; imagem_url: string | null; link_url: string | null; rede_id: number | null }

const colunas = 'id,texto_original,preco,preco_de,preco_clube,condicao,secao,validade_fim,rede_id,rede_nome,rede_slug,itens,preco_referencia,unidade_referencia';

let cache: Promise<{ ofertas: Oferta[]; redes: Rede[]; lojas: Loja[]; anuncios: Anuncio[] }> | undefined;

export function dados() {
  conferirConfig();
  cache ??= (async () => {
    const [ofertas, redes, lojas, anuncios] = await Promise.all([
      lerTudo<Oferta>('oferta_lista', `select=${colunas}&order=id.desc`),
      lerTudo<Rede>('rede_com_ofertas', 'select=*&order=nome'),
      lerTudo<Loja>('loja', 'select=rede_id,nome,lat,lng&lat=not.is.null'),
      lerTudo<Anuncio>('anuncio_vigente', 'select=id,formato,titulo,texto,imagem_url,link_url,rede_id&order=id'),
    ]);
    return { ofertas, redes, lojas, anuncios };
  })();
  return cache;
}
