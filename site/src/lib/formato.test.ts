// node --test (Node 24 roda TypeScript direto). Mesmos casos do app/test/logica_test.dart.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { reais, valeAte, nomeDaOferta, intercalar, distanciaKm, textoDistancia, porUnidade, avisoValidade, hojeEmGV, atualizadoEm, atacado, condicaoCurta, type Oferta } from './formato.ts';

test('atacado: selo e condição curta no card', () => {
  const com = (condicao: string | null) => ({ condicao }) as Oferta;
  const atac = 'preço de atacado: vale na compra em quantidade (mesma fragrância/sabor)';
  assert.equal(atacado(com(atac)), true);
  assert.equal(condicaoCurta(com(atac)), null);
  assert.equal(condicaoCurta(com(`${atac}; leve 12 pague 11`)), 'leve 12 pague 11');
  assert.equal(atacado(com('leve 12 pague 11')), false);
  assert.equal(condicaoCurta(com('leve 12 pague 11')), 'leve 12 pague 11');
  assert.equal(atacado(com(null)), false);
});

test('reais', () => {
  assert.equal(reais(4.99), 'R$ 4,99');
  assert.equal(reais(1234.5), 'R$ 1.234,50');
  assert.equal(reais(0), 'R$ 0,00');
});

test('validade: 03/11/2026 é terça', () => assert.equal(valeAte('2026-11-03'), 'Vale até terça, 03/11'));

test('nome da oferta', () => {
  assert.equal(nomeDaOferta({ itens: [{ nome: 'Arroz 5kg', marca: 'Camil' }], texto_original: 'x' }), 'Arroz 5kg Camil');
  assert.equal(nomeDaOferta({ itens: [{ nome: 'A' }, { nome: 'B' }], texto_original: 'A ou B R$ 1,99' }), 'A ou B');
  const t = 'Mac Espag ou Cortado Don Sapore 400g R$ 1,99';
  assert.equal(nomeDaOferta({ itens: [{ nome: 'Macarrão Espaguete', marca: 'Don Sapore' }, { nome: 'Macarrão Cortado', marca: 'Don Sapore' }], texto_original: t }),
    'Macarrão Espaguete ou Macarrão Cortado Don Sapore');
  assert.equal(nomeDaOferta({ itens: [{ nome: 'Cerveja Pilsen', marca: 'Brahma' }, { nome: 'Cerveja Pilsen', marca: 'Skol' }], texto_original: t }),
    'Cerveja Pilsen Brahma ou Cerveja Pilsen Skol');
  assert.equal(nomeDaOferta({ itens: [], texto_original: t }), t);
});

test('anúncio a cada 8 ofertas, nunca sobrando no fim sem 8 antes', () => {
  const r = intercalar([...Array(17).keys()], ['a', 'b', 'c'], 8);
  assert.deepEqual(r.map((x) => ('anuncio' in x ? x.anuncio : '.')).join(''), '........a........b.');
  assert.equal(intercalar([1, 2], ['a'], 8).length, 2);
});

test('distância', () => {
  assert.ok(Math.abs(distanciaKm(-18.85, -41.95, -18.86, -41.95) - 1.11) < 0.01);
  assert.equal(textoDistancia(0.83), '800 m');
  assert.equal(textoDistancia(2.14), '2,1 km');
});

test('preço por unidade', () => {
  assert.equal(porUnidade(4.76, 'kg'), 'R$ 4,76 o kg');
  assert.equal(porUnidade(null, 'kg'), null);
  assert.equal(porUnidade(9.98, 'l', 4.99), 'R$ 9,98 o litro');
  assert.equal(porUnidade(4.99, 'kg', 4.99), null); // igual ao preço: não repete
  assert.equal(porUnidade(1.5, 'un', 9), 'R$ 1,50 cada'); // pacote
  assert.equal(porUnidade(3.49, 'un', 3.49), null); // unidade solta: "cada" repetiria o preço
  assert.equal(porUnidade(2.5, null), null);
});

test('avisoValidade: hoje, amanhã, venceu, e nada quando falta mais', () => {
  assert.equal(avisoValidade('2026-10-20', '2026-10-20'), 'Vence hoje');
  assert.equal(avisoValidade('2026-11-01', '2026-10-31'), 'Vence amanhã');
  assert.equal(avisoValidade('2026-10-19', '2026-10-20'), 'Encarte venceu');
  assert.equal(avisoValidade('2026-10-25', '2026-10-20'), null);
});

test('hojeEmGV usa o fuso de Brasília', () => {
  assert.equal(hojeEmGV(new Date('2026-10-21T02:30:00Z')), '2026-10-20'); // 23:30 em GV
});

test('atualizadoEm na hora de GV', () => {
  assert.equal(atualizadoEm('2026-10-21T11:12:00+00:00'), 'Ofertas atualizadas em 21/10 às 08:12');
  assert.equal(atualizadoEm('2026-10-21T02:30:00Z'), 'Ofertas atualizadas em 20/10 às 23:30');
});
