import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lerOrigem, linkDaLoja, origemAtual } from './origem.ts';

const play = 'https://play.google.com/store/apps/details?id=br.com.promocaonamao.app';
const apple = 'https://apps.apple.com/app/id6831775636';

test('lê público e criativo; ignora o que não conhece', () => {
  assert.deepEqual(lerOrigem('?p=jovens&c=a2'), { p: 'jovens', c: 'A2' });
  assert.deepEqual(lerOrigem('?p=Adultos&c=B6v2'), { p: 'adultos', c: 'B6V2' });
  assert.deepEqual(lerOrigem('?p=vizinhas&c=<script>'), { p: 'vizinhas', c: null });
  assert.equal(lerOrigem('?p=outro&c=A1'), null);
  assert.equal(lerOrigem(''), null);
});

test('App Store: provider token e ct com público e criativo', () => {
  const u = new URL(linkDaLoja('ios', apple, { p: 'jovens', c: 'A2' }));
  assert.equal(u.searchParams.get('pt'), '129712555');
  assert.equal(u.searchParams.get('ct'), 'ads-jovens-A2');
  assert.equal(u.searchParams.get('mt'), '8');
  assert.equal(new URL(linkDaLoja('ios', apple, null)).searchParams.get('ct'), 'site');
});

test('Google Play: referrer com utm, mantendo o id do app', () => {
  const u = new URL(linkDaLoja('android', play, { p: 'adultos', c: 'B1' }));
  assert.equal(u.searchParams.get('id'), 'br.com.promocaonamao.app');
  const ref = new URLSearchParams(u.searchParams.get('referrer')!);
  assert.equal(ref.get('utm_source'), 'meta');
  assert.equal(ref.get('utm_campaign'), 'ads-adultos');
  assert.equal(ref.get('utm_content'), 'B1');
  const site = new URLSearchParams(new URL(linkDaLoja('android', play, null)).searchParams.get('referrer')!);
  assert.equal(site.get('utm_campaign'), 'site');
  assert.equal(site.get('utm_content'), null);
});

test('origem guardada vale por 30 dias; a da URL troca a guardada', () => {
  const mem = new Map<string, string>();
  globalThis.localStorage = { getItem: (k: string) => mem.get(k) ?? null, setItem: (k: string, v: string) => void mem.set(k, v) } as Storage;
  const dia = 24 * 3600 * 1000;
  assert.deepEqual(origemAtual('?p=jovens&c=A1', 0), { p: 'jovens', c: 'A1' });
  assert.deepEqual(origemAtual('', 29 * dia), { p: 'jovens', c: 'A1' });
  assert.equal(origemAtual('', 31 * dia), null);
  assert.deepEqual(origemAtual('?p=adultos', 32 * dia), { p: 'adultos', c: null });
});
