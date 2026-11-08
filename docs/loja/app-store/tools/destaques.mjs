// Imagens "Header" (3840×1646, 21:9) e "Search Results" (3840×2560, 3:2) do App Store Connect (iOS 27+):
// três telas reais do app em molduras de celular sobre o verde da marca. Uso: node destaques.mjs <pasta-cru> <saida>
import { chromium } from 'playwright-core';
import fs from 'node:fs';

const [cru, saida] = process.argv.slice(2);
const fonte = fs.readFileSync('C:/projetos/promocao/promocao-na-mao/app/assets/fontes/Fredoka-SemiBold.ttf').toString('base64');
const tela = (n) => `data:image/png;base64,${fs.readFileSync(`${cru}/${n}.png`).toString('base64')}`;
const cel = (n, w, extra = '') =>
  `<div class="cel" style="width:${w}px;${extra}"><img src="${tela(n)}"></div>`;
const css = `
  @font-face { font-family: Fredoka; src: url(data:font/ttf;base64,${fonte}); }
  body { margin: 0; overflow: hidden; background: radial-gradient(circle at 50% 30%, #2a8f7b, #1f7a68 55%, #155c4f); }
  .linha { position: absolute; left: 0; right: 0; display: flex; justify-content: center; align-items: flex-start; gap: 120px; }
  .cel { border: 22px solid #143d35; border-bottom: 0; border-radius: 100px 100px 0 0; overflow: hidden; background: #143d35;
         box-shadow: 0 40px 120px rgba(0,0,0,.35); }
  .cel img { display: block; width: 100%; border-radius: 80px 80px 0 0; }
  h1 { font: 600 190px/1.1 Fredoka; color: #fff; text-align: center; margin: 0; padding-top: 210px; }`;

const pecas = [
  // Header: sem texto (a Apple põe o nome e o ícone do app por cima); telas sangrando para baixo.
  ['header', 3840, 1646, `<div class="linha" style="top:250px">
      ${cel('2-busca', 760, 'margin-top:160px')}${cel('1-inicio', 820)}${cel('4-lista', 760, 'margin-top:160px')}</div>`],
  ['busca', 3840, 2560, `<h1>As ofertas de GV numa lista só</h1><div class="linha" style="top:720px">
      ${cel('2-busca', 860, 'margin-top:140px')}${cel('1-inicio', 920)}${cel('4-lista', 860, 'margin-top:140px')}</div>`],
];
fs.mkdirSync(saida, { recursive: true });
const b = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
for (const [nome, w, h, corpo] of pecas) {
  const p = await b.newPage({ viewport: { width: w, height: h } });
  await p.setContent(`<!doctype html><style>${css} body{width:${w}px;height:${h}px}</style>${corpo}`);
  await p.evaluate(() => document.fonts.ready);
  await p.screenshot({ path: `${saida}/${nome}-${w}x${h}.png` });
  console.log('ok', nome);
}
await b.close();
