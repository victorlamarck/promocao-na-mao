// API REST do Supabase (PostgREST) com fetch puro: o navegador não baixa a biblioteca
// supabase-js só para isso (ela entra apenas para o tempo real da lista, sob demanda).
import { supabaseUrl, supabaseChave } from './config';

const cabecalhos = { apikey: supabaseChave, Authorization: `Bearer ${supabaseChave}` };

async function resposta<T>(r: Response): Promise<T> {
  const corpo = await r.json().catch(() => null);
  if (!r.ok) throw new Error(corpo?.message ?? `erro ${r.status}`);
  return corpo as T;
}

/** Chama uma função SQL (RPC). */
export const rpc = <T>(funcao: string, args: Record<string, unknown> = {}) =>
  fetch(`${supabaseUrl}/rest/v1/rpc/${funcao}`, {
    method: 'POST',
    headers: { ...cabecalhos, 'Content-Type': 'application/json' },
    body: JSON.stringify(args),
  }).then(resposta<T>);

/** buscar_ofertas (migration 7) com filtro de mercado, ordem e página; devolve também o total. */
export async function buscar(termo: string, { rede, menorPreco, de, quantos }: { rede?: string; menorPreco: boolean; de: number; quantos: number }) {
  const q = new URLSearchParams();
  if (rede) q.set('rede_slug', `eq.${rede}`);
  if (menorPreco) q.set('order', 'preco.asc.nullslast,id');
  const r = await fetch(`${supabaseUrl}/rest/v1/rpc/buscar_ofertas?${q}`, {
    method: 'POST',
    headers: { ...cabecalhos, 'Content-Type': 'application/json', Range: `${de}-${de + quantos - 1}`, Prefer: 'count=exact' },
    body: JSON.stringify({ termo }),
  });
  const total = Number(r.headers.get('content-range')?.split('/')[1] ?? 0);
  return { ofertas: await resposta<import('./formato').Oferta[]>(r), total };
}

/** Lê uma view/tabela inteira, de 1.000 em 1.000 (limite do PostgREST). `consulta` = "select=...&order=...". */
export async function lerTudo<T>(tabela: string, consulta: string): Promise<T[]> {
  const todas: T[] = [];
  for (let de = 0; ; de += 1000) {
    const r = await fetch(`${supabaseUrl}/rest/v1/${tabela}?${consulta}`, {
      headers: { ...cabecalhos, Range: `${de}-${de + 999}` },
    });
    const pagina = await resposta<T[]>(r);
    todas.push(...pagina);
    if (pagina.length < 1000) return todas;
  }
}
