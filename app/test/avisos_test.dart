import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/features/avisos/meus_avisos_page.dart';

void main() {
  test('nome do produto avisado: nome, marca e tamanho; busca sem o tamanho', () {
    final p = ProdutoAvisado.fromJson({'codigo': 'c', 'nome': 'Café', 'marca': 'Pilão', 'quantidade': 500, 'unidade': 'g'});
    expect(p.nome, 'Café Pilão 500g');
    expect(p.busca, 'Café Pilão');
    expect(ProdutoAvisado.fromJson({'codigo': 'c', 'nome': 'Óleo', 'marca': null, 'quantidade': 0.9, 'unidade': 'l'}).nome, 'Óleo 0,9l');
    expect(ProdutoAvisado.semCatalogo('x').busca, isNull);
  });

  testWidgets('sem avisos ligados: explica onde fica o sino', (t) async {
    await t.pumpWidget(const MaterialApp(home: MeusAvisosPage()));
    expect(find.text('Nenhum aviso ligado ainda.'), findsOneWidget);
  });
}
