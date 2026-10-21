// /previa/<id>.png: prévia de cada oferta (nome, preço, mercado) e /previa/site.png e lista.png.
import type { APIRoute } from 'astro';
import sharp from 'sharp';
import { dados } from '../../lib/dados';
import { diaMes, nomeDaOferta, reais } from '../../lib/formato';
import { svgPrevia } from '../../lib/previa';

export async function getStaticPaths() {
  const { ofertas } = await dados();
  return [
    { params: { id: 'site' }, props: { titulo: 'As ofertas dos mercados de GV numa lista só', rodape: 'Encartes atualizados · Governador Valadares' } },
    { params: { id: 'lista' }, props: { titulo: 'Uma lista de compras pra você', rodape: 'Abra para ver e marcar o que já pegou' } },
    ...ofertas.map((o) => ({
      params: { id: String(o.id) },
      props: {
        titulo: nomeDaOferta(o),
        preco: o.preco == null ? 'Preço no mercado' : reais(o.preco),
        rodape: `${o.rede_nome} · até ${diaMes(o.validade_fim)}`,
      },
    })),
  ];
}

export const GET: APIRoute = async ({ props }) =>
  new Response(new Uint8Array(await sharp(Buffer.from(svgPrevia(props as Parameters<typeof svgPrevia>[0]))).png({ palette: true }).toBuffer()), {
    headers: { 'Content-Type': 'image/png' },
  });
