// Mesmas regras de texto do app (app/lib/core/formato.dart e modelos.dart).

export interface Oferta {
  id: number;
  texto_original: string;
  preco: number | null;
  preco_de: number | null;
  preco_clube: number | null;
  condicao: string | null;
  secao: string | null;
  validade_fim: string; // "2026-11-03"
  rede_id: number;
  rede_nome: string;
  rede_slug: string;
  itens: { nome?: string | null; marca?: string | null }[];
  preco_referencia: number | null;
  unidade_referencia: string | null;
}

/** Oferta de folheto de atacado: a condição começa com "preço de atacado" (como o `atacado` do app). */
// shortcut: depende do texto da extração; virar coluna na API se outra rede tiver folheto de atacado.
export const atacado = (o: Oferta) => o.condicao?.startsWith('preço de atacado') ?? false;

/** Condição para o card, sem o que ele já mostra: o "preço de atacado: ..." (selo "Preço de atacado") e o
 *  "preço clube: ..." quando há preço de clube (etiqueta "R$ X com bigmais+"). O texto todo fica na página da oferta.
 *  Mesma regra do `condicaoCurta` do app (modelos.dart); null se não sobrar nada. */
// shortcut: as partes vêm separadas por ";" e com esses começos na extração; se mudar, o card volta a repetir.
export function condicaoCurta(o: Oferta): string | null {
  const resto = (o.condicao ?? '').split(';').map((p) => p.trim())
    .filter((p) => p && !p.startsWith('preço de atacado') && !(o.preco_clube != null && p.startsWith('preço clube')));
  return resto.join('; ') || null;
}

/** 4.99 → "R$ 4,99"; 1234.5 → "R$ 1.234,50". */
export function reais(v: number): string {
  const [inteiro, centavos] = v.toFixed(2).split('.');
  return `R$ ${inteiro.replace(/\B(?=(\d{3})+$)/g, '.')},${centavos}`;
}

const dd = (n: number) => String(n).padStart(2, '0');
// A data vem sem hora ("2026-11-03"): ler como data local, sem fuso.
const data = (iso: string) => { const [a, m, d] = iso.slice(0, 10).split('-').map(Number); return new Date(a, m - 1, d); };

/** "03/11". */
export const diaMes = (iso: string) => { const d = data(iso); return `${dd(d.getDate())}/${dd(d.getMonth() + 1)}`; };

const dias = ['domingo', 'segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado'];
/** "Vale até terça, 03/11". */
export const valeAte = (iso: string) => `Vale até ${dias[data(iso).getDay()]}, ${diaMes(iso)}`;

/** "2026-10-20": o dia de hoje em GV, seja qual for o fuso de quem roda (o build roda em UTC). */
export const hojeEmGV = (agora = new Date()) => agora.toLocaleDateString('en-CA', { timeZone: 'America/Sao_Paulo' });

/** "Ofertas atualizadas em 21/10 às 08:12" (hora de GV). A página é gerada no build: data fixa, não "hoje". */
export function atualizadoEm(iso: string) {
  const p = Object.fromEntries(new Intl.DateTimeFormat('pt-BR', { timeZone: 'America/Sao_Paulo', day: '2-digit', month: '2-digit',
    hour: '2-digit', minute: '2-digit', hourCycle: 'h23' }).formatToParts(new Date(iso)).map((x) => [x.type, x.value]));
  return `Ofertas atualizadas em ${p.day}/${p.month} às ${p.hour}:${p.minute}`;
}

/** Aviso no card e na lista: "Vence hoje", "Vence amanhã", "Encarte venceu"; null quando falta mais. */
export function avisoValidade(fim: string, hoje = hojeEmGV()): string | null {
  const n = Math.round((data(fim).getTime() - data(hoje).getTime()) / 864e5);
  return n < 0 ? 'Encarte venceu' : n === 0 ? 'Vence hoje' : n === 1 ? 'Vence amanhã' : null;
}

/** "R$ 4,76 o kg" / "R$ 1,50 cada" (pacote). Nada quando repete o preço exibido. */
export function porUnidade(valor: number | null, unidade: string | null, preco: number | null = null): string | null {
  if (valor == null || !unidade || (preco != null && reais(valor) === reais(preco))) return null;
  return `${reais(valor)} ${unidade === 'kg' ? 'o kg' : unidade === 'l' ? 'o litro' : 'cada'}`;
}

/** Nome para o card, montado dos itens (o texto do encarte às vezes traz preço e regras):
 *  "Macarrão Espaguete ou Macarrão Cortado Don Sapore". Sem itens, o texto do encarte. Igual ao app. */
export function nomeDaOferta(o: Pick<Oferta, 'itens' | 'texto_original'>): string {
  if (o.itens.length === 0) return o.texto_original;
  const junta = (partes: (string | null | undefined)[]) => partes.filter(Boolean).join(' ');
  const unicos = (xs: string[]) => [...new Set(xs)];
  const marcas = unicos(o.itens.map((i) => i.marca ?? ''));
  if (marcas.length === 1) return junta([unicos(o.itens.map((i) => i.nome ?? '').filter(Boolean)).join(' ou '), marcas[0]]);
  return unicos(o.itens.map((i) => junta([i.nome, i.marca]))).join(' ou ');
}

/** Cor, sigla e nome do clube de cada rede (app/lib/core/tema.dart). */
const mercados: Record<string, { cor: string; sigla: string; clube?: string }> = {
  'big-mais': { cor: '#1D4ED8', sigla: 'BM', clube: 'bigmais+' },
  'coelho-diniz': { cor: '#B45309', sigla: 'CD' },
  atacadao: { cor: '#0F766E', sigla: 'AT', clube: 'app Meu Atacadão' },
  'supermercados-bh': { cor: '#6D28D9', sigla: 'BH', clube: 'Meu BH' },
  'mart-minas': { cor: '#BE123C', sigla: 'MM', clube: 'Mart Mais' },
};
export const mercado = (slug: string | null | undefined) =>
  (slug && mercados[slug]) || { cor: '#707971', sigla: slug ? slug.slice(0, 2).toUpperCase() : '?', clube: undefined };

/** Distância em km entre dois pontos (haversine). */
export function distanciaKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const r = (g: number) => (g * Math.PI) / 180;
  const a = Math.sin(r(lat2 - lat1) / 2) ** 2 + Math.cos(r(lat1)) * Math.cos(r(lat2)) * Math.sin(r(lng2 - lng1) / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(a));
}

/** "800 m" / "2,1 km". */
export const textoDistancia = (km: number) => (km < 1 ? `${Math.round(km * 10) * 100} m` : `${km.toFixed(1).replace('.', ',')} km`);

/** Itens de 1 em 1 a cada `n` posições recebem um anúncio (máx. 1 a cada n ofertas). */
export function intercalar<T, A>(itens: T[], anuncios: A[], n: number): ({ oferta: T } | { anuncio: A })[] {
  const saida: ({ oferta: T } | { anuncio: A })[] = [];
  itens.forEach((o, i) => {
    saida.push({ oferta: o });
    const a = anuncios[Math.floor((i + 1) / n) - 1];
    if ((i + 1) % n === 0 && a) saida.push({ anuncio: a });
  });
  return saida;
}
