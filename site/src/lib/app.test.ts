import { test } from 'node:test';
import assert from 'node:assert/strict';
import { faixaFechadaRecente, idAppStore, linkDoApp } from './app.ts';

const local = { host: 'www.promocaonamao.com.br', pathname: '/l/abc123', search: '' };
const lojas = { android: 'https://play.google.com/store/apps/details?id=br.com.promocaonamao.app', ios: 'https://apps.apple.com/app/id1', pacote: 'br.com.promocaonamao.app' };

test('Android: intent para a mesma página, com a Play Store de reserva', () => {
  const l = linkDoApp('Mozilla/5.0 (Linux; Android 14)', local, lojas)!;
  assert.ok(l.startsWith('intent://www.promocaonamao.com.br/l/abc123#Intent;scheme=https;package=br.com.promocaonamao.app;'));
  assert.ok(l.includes('S.browser_fallback_url=' + encodeURIComponent(lojas.android)));
});
test('iPhone: App Store', () => assert.equal(linkDoApp('Mozilla/5.0 (iPhone; CPU iPhone OS 18_0)', local, lojas), lojas.ios));
test('computador ou loja não configurada: nada', () => {
  assert.equal(linkDoApp('Mozilla/5.0 (Windows NT 10.0)', local, lojas), null);
  assert.equal(linkDoApp('Mozilla/5.0 (Linux; Android 14)', local, { ...lojas, android: '' }), null);
});
test('ID da App Store para a faixa do Safari', () => {
  assert.equal(idAppStore('https://apps.apple.com/br/app/promocao-na-mao/id6754123456?pt=1'), '6754123456');
  assert.equal(idAppStore(''), null);
});
test('faixa do Android fechada: some por 30 dias', () => {
  const dia = 86_400_000, agora = 100 * dia;
  assert.equal(faixaFechadaRecente(null, agora), false);
  assert.equal(faixaFechadaRecente(String(agora - 29 * dia), agora), true);
  assert.equal(faixaFechadaRecente(String(agora - 31 * dia), agora), false);
  assert.equal(faixaFechadaRecente('lixo', agora), false);
});
