// Link que abre o app na MESMA página (Android: intent com fallback para a Play Store; iPhone: App Store).
export function linkDoApp(ua: string, local: { host: string; pathname: string; search: string }, d: { android?: string; ios?: string; pacote?: string }) {
  if (/Android/i.test(ua) && d.android)
    return `intent://${local.host}${local.pathname}${local.search}#Intent;scheme=https;package=${d.pacote};S.browser_fallback_url=${encodeURIComponent(d.android)};end`;
  if (/iPhone|iPad|iPod/i.test(ua) && d.ios) return d.ios;
  return null;
}
