import { test } from 'node:test';
import assert from 'node:assert/strict';
import { linhas, escapar, svgPrevia } from './previa.ts';

test('linhas quebra por palavra e corta com reticências', () => {
  assert.deepEqual(linhas('Arroz Camil tipo 1 5kg', 12, 3), ['Arroz Camil', 'tipo 1 5kg']);
  const l = linhas('um dois tres quatro cinco seis sete oito', 9, 2);
  assert.equal(l.length, 2);
  assert.ok(l[1].endsWith('…') && l[1].length <= 9);
});

test('nome do encarte com & e < não quebra o SVG', () => {
  assert.equal(escapar('Leite & <Café>'), 'Leite &amp; &lt;Café&gt;');
  assert.ok(!svgPrevia({ titulo: 'A & B', preco: 'R$ 1,00', rodape: 'x' }).includes('A & B'));
});

test('caractere de controle do PDF não quebra o SVG (o build cairia)', () => {
  assert.equal(escapar('Arroz\u0001Camil\u000B'), 'ArrozCamil');
  assert.equal(escapar('a\tb'), 'a\tb');
});
