// Link que abre o app na MESMA página (Android: intent com fallback para a Play Store; iPhone: App Store).
export function linkDoApp(ua: string, local: { host: string; pathname: string; search: string }, d: { android?: string; ios?: string; pacote?: string }) {
  if (/Android/i.test(ua) && d.android)
    return `intent://${local.host}${local.pathname}${local.search}#Intent;scheme=https;package=${d.pacote};S.browser_fallback_url=${encodeURIComponent(d.android)};end`;
  if (/iPhone|iPad|iPod/i.test(ua) && d.ios) return d.ios;
  return null;
}

/** ID numérico do app na App Store (…/id6754123456) para a faixa nativa do Safari (meta apple-itunes-app). */
export function idAppStore(url: string) {
  return /\/id(\d+)/.exec(url)?.[1] ?? null;
}

/** Faixa "Baixe o app" no Android: fechada há menos de [dias] não volta. */
export function faixaFechadaRecente(fechadaEm: string | null, agora: number, dias = 30) {
  const t = Number(fechadaEm);
  return fechadaEm != null && Number.isFinite(t) && agora - t < dias * 86_400_000;
}
