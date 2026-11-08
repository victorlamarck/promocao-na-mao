// Reduz as capturas 1320×2868 (iPhone 6,9") para 1206×2622 (6,3", "medium display" do App Store Connect).
import { chromium } from 'playwright-core';
import fs from 'node:fs';
const [ent, sai] = process.argv.slice(2);
fs.mkdirSync(sai, { recursive: true });
const b = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe' });
const p = await b.newPage({ viewport: { width: 1206, height: 2622 } });
for (const f of fs.readdirSync(ent).filter((n) => n.endsWith('.png'))) {
  await p.setContent(`<body style="margin:0"><img style="display:block;width:1206px;height:2622px" src="data:image/png;base64,${fs.readFileSync(`${ent}/${f}`).toString('base64')}">`);
  await p.screenshot({ path: `${sai}/${f}`, omitBackground: false });
  console.log('ok', f);
}
await b.close();
