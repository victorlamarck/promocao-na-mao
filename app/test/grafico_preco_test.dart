import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/modelos.dart';
import 'package:promocao_na_mao/features/oferta/grafico_preco.dart';

PeriodoPreco periodo(String slug, String inicio, String fim, double preco) => PeriodoPreco.fromJson({
      'rede_slug': slug, 'rede_nome': slug == 'atacadao' ? 'Atacadão' : 'Big Mais',
      'dia_inicio': inicio, 'dia_fim': fim, 'preco': preco,
    });

void main() {
  final hoje = DateTime(2026, 11, 19, 15);
  final periodos = [
    periodo('atacadao', '2026-10-01', '2026-10-10', 2.49), // fora dos 30 dias
    periodo('atacadao', '2026-11-10', '2026-11-15', 3.49),
    periodo('atacadao', '2026-11-16', '2026-11-19', 2.99),
    periodo('big-mais', '2026-11-12', '2026-11-19', 3.19),
  ];

  test('menor preço em 30 dias: ignora o que acabou antes', () {
    expect(menorEm30Dias(periodos, hoje), (preco: 2.99, mercado: 'Atacadão'));
    expect(menorEm30Dias([periodos.first], hoje), isNull);
  });

  test('só desenha com 2 dias ou mais', () {
    expect(temHistorico(const []), isFalse);
    expect(temHistorico([periodo('atacadao', '2026-11-19', '2026-11-19', 3)]), isFalse);
    expect(temHistorico([periodo('atacadao', '2026-11-18', '2026-11-19', 3)]), isTrue);
    expect(temHistorico([periodo('atacadao', '2026-11-17', '2026-11-17', 3), periodo('big-mais', '2026-11-19', '2026-11-19', 3)]), isTrue);
  });

  test('produto da oferta para o gráfico: o do 1º item que tem', () {
    Oferta oferta(List<Map<String, dynamic>> itens) => Oferta.fromJson({
          'id': 1, 'texto_original': 'X', 'preco_por': 'embalagem', 'validade_fim': '2099-01-01',
          'rede_id': 1, 'rede_nome': 'Atacadão', 'rede_slug': 'atacadao', 'itens': itens,
        });
    expect(oferta([{'produto_id': null}, {'produto_id': 7}, {'produto_id': 9}]).produtoId, 7);
    expect(oferta([{'produto_id': null}]).produtoId, isNull);
    expect(oferta([]).produtoId, isNull);
  });

  testWidgets('cartão: frase do menor preço, mercados e descrição para o leitor de tela', (t) async {
    final semantica = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(home: Scaffold(body: CartaoGraficoPreco(periodos, hoje: hoje))));
    expect(find.text('Menor preço em 30 dias: R\$ 2,99 no Atacadão'), findsOneWidget);
    expect(find.text('Atacadão'), findsOneWidget);
    expect(find.text('Big Mais'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Gráfico do preço de 01/10 a 19/11: de R\$ 2,49 a R\$ 3,49')), findsOneWidget);
    semantica.dispose();
  });
}
