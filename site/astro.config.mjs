import { defineConfig } from 'astro/config';
import preact from '@astrojs/preact';
import sitemap from '@astrojs/sitemap';

// Site estático: as páginas de ofertas são geradas no build (a esteira refaz a cada
// atualização dos dados e todo dia de madrugada). Busca e lista rodam no navegador.
export default defineConfig({
  site: process.env.SITE_URL ?? 'https://www.promocaonamao.com.br',
  integrations: [preact(), sitemap({ filter: (p) => !p.includes('/l/') })],
});
