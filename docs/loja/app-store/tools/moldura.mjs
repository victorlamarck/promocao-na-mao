// Monta as capturas da App Store: fundo da marca, legenda em Fredoka e a tela do app numa moldura de celular.
// Saída 1320×2868 (iPhone 6,9") ou, com "play", 1080×1920 (Google Play, 9:16: o mesmo desenho em escala, o celular
// cortado mais acima). Uso: node moldura.mjs <pasta-cru> <pasta-saida> [play|ios] [legendas.json]
// legendas.json: [["nome-do-png", "Legenda"], ...] (páginas personalizadas por público); sem ele, as 5 telas abaixo.
import { chromium } from 'playwright-core';
import fs from 'node:fs';

const [cru, saida, loja, legendas] = process.argv.slice(2);
const escala = loja === 'play' ? 1080 / 1320 : 1;
const altura = loja === 'play' ? 2347 : 2868; // 2347 × 1080/1320 = 1920
const fonte = fs.readFileSync('C:/projetos/promocao/promocao-na-mao/app/assets/fontes/Fredoka-SemiBold.ttf').toString('base64');
const telas = legendas ? JSON.parse(fs.readFileSync(legendas, 'utf8')) : [
  ['1-inicio', 'As ofertas de hoje dos mercados de GV'],
  ['2-preco', 'Veja como o preço variou em cada mercado'],
  ['3-busca', 'Busque o produto em todos os encartes'],
  ['4-lista', 'Sua lista já separada por mercado'],
  ['5-mercados', 'Os mercados da cidade num lugar só'],
];
fs.mkdirSync(saida, { recursive: true });
const b = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
const p = await b.newPage({ viewport: { width: 1320, height: altura }, deviceScaleFactor: escala });
for (const [nome, legenda] of telas) {
  const img = fs.readFileSync(`${cru}/${nome}.png`).toString('base64');
  await p.setContent(`<!doctype html><style>
    @font-face { font-family: Fredoka; src: url(data:font/ttf;base64,${fonte}); }
    body { margin: 0; width: 1320px; height: ${altura}px; overflow: hidden; background: #1f7a68; }
    h1 { font: 600 112px/1.12 Fredoka; color: #fff; text-align: center; margin: 0; padding: 170px 120px 0; height: 480px; box-sizing: border-box; }
    .cel { position: absolute; left: 140px; top: 592px; width: 1040px; border: 26px solid #143d35; border-bottom: 0;
           border-radius: 120px 120px 0 0; overflow: hidden; background: #143d35; }
    .cel img { display: block; width: 100%; border-radius: 96px 96px 0 0; }
  </style><h1>${legenda}</h1><div class="cel"><img src="data:image/png;base64,${img}"></div>`);
  await p.evaluate(() => document.fonts.ready);
  await p.screenshot({ path: `${saida}/${nome}.png` });
  console.log('ok', nome);
}
await b.close();
