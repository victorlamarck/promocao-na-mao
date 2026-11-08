// Serve o build web do app (com fallback de SPA) e fotografa telas no tamanho de iPhone (390×844 ×3).
// Uso: node fotos.mjs <pasta-build-web> <pasta-saida> <roteiro.json>
// Roteiro: lista de passos [acao, ...args]: ["ir", rota] ["tocar", nomeDoBotao, indice?] ["campo", texto]
//          ["tecla", nome] ["rolar", px] ["esperar", ms] ["foto", nome] ["xy", x, y]
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright-core';

const [web, saida, roteiro] = process.argv.slice(2);
const tipos = { '.js': 'text/javascript', '.mjs': 'text/javascript', '.html': 'text/html', '.json': 'application/json',
  '.wasm': 'application/wasm', '.css': 'text/css', '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf' };
const raiz = path.resolve(web);
const srv = http.createServer((req, res) => {
  let f = path.resolve(raiz, '.' + decodeURIComponent(req.url.split('?')[0]));
  if (!f.startsWith(raiz) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(raiz, 'index.html');
  res.writeHead(200, { 'content-type': tipos[path.extname(f)] ?? 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
}).listen(8765);

const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
const ctx = await browser.newContext({
  viewport: { width: 390, height: 844 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true,
  locale: 'pt-BR', timezoneId: 'America/Sao_Paulo', permissions: [], // localização negada: não mostra onde o dev está
});
const page = await ctx.newPage();
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));
fs.mkdirSync(saida, { recursive: true });

async function semantica() {
  // O Flutter web só monta a árvore de acessibilidade (botões com nome) depois deste toque.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await esperar(500);
}

for (const [acao, ...a] of JSON.parse(fs.readFileSync(roteiro, 'utf8'))) {
  if (acao === 'ir') { await page.goto(`http://localhost:8765${a[0]}`); await esperar(8000); await semantica(); }
  else if (acao === 'tocar') { await page.getByRole('button').filter({ hasText: new RegExp(a[0], 'i') }).nth(a[1] ?? 0).click({ force: true, timeout: 8000 }); await esperar(2500); }
  else if (acao === 'campo') { await page.mouse.click(195, 40); await esperar(600); await page.keyboard.press('Control+A'); await page.keyboard.type(a[0], { delay: 40 }); await esperar(500); }
  else if (acao === 'tecla') { await page.keyboard.press(a[0]); await esperar(4000); }
  else if (acao === 'rolar') { await page.mouse.move(195, 500); await page.mouse.wheel(0, a[0]); await esperar(1500); }
  else if (acao === 'xy') { await page.mouse.click(a[0], a[1]); await esperar(2500); }
  else if (acao === 'cartao') { await page.locator(`[aria-label*="${a[0]}"]`).first().click({ force: true, timeout: 8000 }); await esperar(3000); }
  else if (acao === 'esperar') await esperar(a[0]);
  else if (acao === 'botoes') console.log(await page.getByRole('button').allInnerTexts().catch(() => []),
    await page.locator('flt-semantics [aria-label]').evaluateAll((els) => els.map((e) => e.getAttribute('aria-label')).slice(0, 40)));
  else if (acao === 'foto') { await page.screenshot({ path: path.join(saida, `${a[0]}.png`) }); console.log('ok', a[0]); }
}
await browser.close();
srv.close();
