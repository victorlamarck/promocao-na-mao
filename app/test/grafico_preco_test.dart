import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/modelos.dart';
import 'package:promocao_na_mao/features/oferta/grafico_preco.dart';

PeriodoPreco periodo(String slug, String inicio, String fim, double preco) => PeriodoPreco.fromJson({
  'rede_slug': slug,
  'rede_nome': slug == 'atacadao' ? 'Atacadão' : 'Big Mais',
  'dia_inicio': inicio,
  'dia_fim': fim,
  'preco': preco,
});

void main() {
  final hoje = DateTime(2026, 11, 19, 15);
  final periodos = [
    periodo('atacadao', '2026-10-01', '2026-10-10', 2.49), // fora dos 30 dias
    periodo('atacadao', '2026-11-10', '2026-11-15', 3.49),
    periodo('atacadao', '2026-11-16', '2026-11-19', 2.99),
    periodo('big-mais', '2026-11-12', '2026-11-19', 3.19),
  ];

  test('menor preço no período: ignora o que acabou antes', () {
    expect(menorEm(periodos, hoje, 30), (preco: 2.99, mercado: 'Atacadão'));
    expect(menorEm([periodos.first], hoje, 30), isNull);
    expect(menorEm(periodos, hoje, 90), (preco: 2.49, mercado: 'Atacadão'));
  });

  test('recorte: só a janela de dias, com o período cortado na borda', () {
    final r = recorte(periodos, hoje, 7); // 13/11 a 19/11
    expect(r.length, 3);
    expect(r.first.inicio, DateTime(2026, 11, 13)); // 10/11–15/11 vira 13/11–15/11
    expect(r.first.fim, DateTime(2026, 11, 15));
    expect(recorte(periodos, hoje, 90).length, 4);
  });

  test('preço de cada mercado num dia', () {
    expect(precosNoDia(periodos, DateTime(2026, 11, 14)).keys, ['Big Mais', 'Atacadão']); // mais barato primeiro
    expect(precosNoDia(periodos, DateTime(2026, 11, 14)), {'Atacadão': 3.49, 'Big Mais': 3.19});
    // hoje ainda sem registro (gravado às 23:50): o gráfico termina ontem
    expect(ultimoDia(periodos, DateTime(2026, 11, 20, 14)), DateTime(2026, 11, 19));
    expect(ultimoDia(periodos, hoje), DateTime(2026, 11, 19));
    expect(precosNoDia(periodos, DateTime(2026, 11, 11)), {'Atacadão': 3.49});
    expect(precosNoDia(periodos, DateTime(2026, 11, 1)), isEmpty);
  });

  test('só desenha com 2 dias ou mais', () {
    expect(temHistorico(const []), isFalse);
    expect(temHistorico([periodo('atacadao', '2026-11-19', '2026-11-19', 3)]), isFalse);
    expect(temHistorico([periodo('atacadao', '2026-11-18', '2026-11-19', 3)]), isTrue);
    expect(
      temHistorico([
        periodo('atacadao', '2026-11-17', '2026-11-17', 3),
        periodo('big-mais', '2026-11-19', '2026-11-19', 3),
      ]),
      isTrue,
    );
  });

  test('produto da oferta para o gráfico: o do 1º item que tem', () {
    Oferta oferta(List<Map<String, dynamic>> itens) => Oferta.fromJson({
      'id': 1,
      'texto_original': 'X',
      'preco_por': 'embalagem',
      'validade_fim': '2099-01-01',
      'rede_id': 1,
      'rede_nome': 'Atacadão',
      'rede_slug': 'atacadao',
      'itens': itens,
    });
    expect(
      oferta([
        {'produto_id': null},
        {'produto_id': 7},
        {'produto_id': 9},
      ]).produtoId,
      7,
    );
    expect(
      oferta([
        {'produto_id': null},
      ]).produtoId,
      isNull,
    );
    expect(oferta([]).produtoId, isNull);
  });

  testWidgets('cartão: frase do menor preço, mercados e descrição para o leitor de tela', (t) async {
    final semantica = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartaoGraficoPreco(periodos, hoje: hoje)),
      ),
    );
    expect(find.text('Menor preço em 30 dias: R\$ 2,99 no Atacadão'), findsOneWidget);
    expect(find.text('Atacadão'), findsOneWidget);
    expect(find.text('Big Mais'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Gráfico do preço de 21/10 a 19/11: de R\$ 2,99 a R\$ 3,49')),
      findsOneWidget,
    );
    // 90D traz o período de outubro; 7D começa em 13/11
    await t.tap(find.text('90D'));
    await t.pump();
    expect(find.text('Menor preço em 90 dias: R\$ 2,49 no Atacadão'), findsOneWidget);
    await t.tap(find.text('7D'));
    await t.pump();
    expect(find.bySemanticsLabel(RegExp(r'^Gráfico do preço de 13/11 a 19/11')), findsOneWidget);
    // tocar no último dia mostra o preço de cada mercado nele
    final grafico = t.getRect(find.bySemanticsLabel(RegExp(r'^Gráfico do preço')));
    await t.tapAt(Offset(grafico.right - 4, grafico.center.dy));
    await t.pump();
    expect(find.text('19/11: Atacadão R\$ 2,99 · Big Mais R\$ 3,19'), findsOneWidget);
    semantica.dispose();
  });
}
