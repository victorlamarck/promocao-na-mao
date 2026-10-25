import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/modelos.dart';
import 'package:promocao_na_mao/core/widgets.dart';
import 'package:promocao_na_mao/features/lista/lista.dart';
import 'package:promocao_na_mao/features/lista/lista_page.dart';

void main() {
  testWidgets('card: uma frase para o leitor de tela, Adicionar à parte', (t) async {
    final semantica = t.ensureSemantics();
    final o = Oferta.fromJson({
      'id': 1, 'texto_original': 'Café 500 g', 'preco': 12.9, 'preco_de': 15.9, 'preco_por': 'embalagem',
      'validade_fim': '2099-01-01', 'rede_id': 1, 'rede_nome': 'Atacadão', 'rede_slug': 'atacadao', 'itens': [],
    });
    await t.pumpWidget(MaterialApp(home: Scaffold(body: CardOferta(o))));
    expect(find.bySemanticsLabel('Café 500 g, R\$ 12,90 no Atacadão, antes R\$ 15,90'), findsOneWidget);
    expect(find.bySemanticsLabel('Adicionar'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('lista carregando: indicador em vez de "0 itens em 0 mercados"', (t) async {
    Lista.minha.carregando = true;
    addTearDown(() => Lista.minha.carregando = false);
    await t.pumpWidget(const MaterialApp(home: ListaPage()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('0 itens'), findsNothing);
  });
}
