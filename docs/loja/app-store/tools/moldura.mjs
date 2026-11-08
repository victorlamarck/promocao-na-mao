// Monta as capturas da App Store: fundo da marca, legenda em Fredoka e a tela do app numa moldura de celular.
// Saída 1320×2868 (iPhone 6,9", o tamanho que a App Store exige). Uso: node moldura.mjs <pasta-cru> <pasta-saida>
import { chromium } from 'playwright-core';
import fs from 'node:fs';

const [cru, saida] = process.argv.slice(2);
const fonte = fs.readFileSync('C:/projetos/promocao/promocao-na-mao/app/assets/fontes/Fredoka-SemiBold.ttf').toString('base64');
const telas = [
  ['1-inicio', 'As ofertas de hoje dos mercados de GV'],
  ['2-busca', 'Busque o produto em todos os encartes'],
  ['3-lista', 'Sua lista já separada por mercado', '4-lista'],
  ['4-oferta', 'Validade, lojas e preço por quilo', '3-oferta'],
  ['5-mercados', 'Os mercados da cidade num lugar só'],
];
fs.mkdirSync(saida, { recursive: true });
const b = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
const p = await b.newPage({ viewport: { width: 1320, height: 2868 } });
for (const [nome, legenda, origem = nome] of telas) {
  const img = fs.readFileSync(`${cru}/${origem}.png`).toString('base64');
  await p.setContent(`<!doctype html><style>
    @font-face { font-family: Fredoka; src: url(data:font/ttf;base64,${fonte}); }
    body { margin: 0; width: 1320px; height: 2868px; overflow: hidden; background: #1f7a68; }
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
