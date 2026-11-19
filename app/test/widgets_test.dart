import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/analytics.dart';
import 'package:promocao_na_mao/core/modelos.dart';
import 'package:promocao_na_mao/core/widgets.dart';
import 'package:promocao_na_mao/features/anuncios/espaco_anuncio.dart';
import 'package:promocao_na_mao/features/lista/lista.dart';
import 'package:promocao_na_mao/features/lista/lista_page.dart';
import 'package:promocao_na_mao/features/oferta/dica.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dica: aparece só na 1ª vez e some com um toque', (t) async {
    SharedPreferences.setMockInitialValues({});
    var usou = false;
    Widget tela() => MaterialApp(
        home: Scaffold(
            body: Dica(id: 'sino', icone: Icons.notifications_none, texto: 'Toque no sino', acao: 'Avisar', onAcao: () => usou = true)));
    await t.pumpWidget(tela());
    await t.pumpAndSettle();
    expect(find.text('Toque no sino'), findsOneWidget);
    await t.tap(find.text('Avisar'));
    await t.pump();
    expect(usou, isTrue);
    expect(find.text('Toque no sino'), findsNothing);

    await t.pumpWidget(const SizedBox()); // sai da tela e volta: já foi vista
    await t.pumpWidget(tela());
    await t.pumpAndSettle();
    expect(find.text('Toque no sino'), findsNothing);
  });

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

  testWidgets('anúncio vendido leva o selo "Patrocinado"', (t) async {
    final a = Anuncio.fromJson({'id': 1, 'formato': 'feed', 'titulo': 'Padaria do Bairro'});
    await t.pumpWidget(MaterialApp(home: Scaffold(body: EspacoAnuncioView(anuncio: a, espaco: 'inicio'))));
    expect(find.text('Patrocinado'), findsOneWidget);
    expect(find.text('Anúncio'), findsNothing);
    expect(find.textContaining('Cupom'), findsNothing); // sem cupom, sem caixa
    novaTela();
  });

  testWidgets('anúncio com cupom: código, regra e validade', (t) async {
    final a = Anuncio.fromJson({
      'id': 2, 'formato': 'feed', 'titulo': 'Padaria do Bairro',
      'cupom_codigo': 'PAO10', 'cupom_regra': '10% no pão', 'fim': '2026-11-30',
    });
    await t.pumpWidget(MaterialApp(home: Scaffold(body: EspacoAnuncioView(anuncio: a, espaco: 'inicio'))));
    expect(find.text('Cupom PAO10'), findsOneWidget);
    expect(find.text('10% no pão · até 30/11'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    novaTela();
  });

  testWidgets('lista carregando: indicador em vez de "0 itens em 0 mercados"', (t) async {
    Lista.minha.carregando = true;
    addTearDown(() => Lista.minha.carregando = false);
    await t.pumpWidget(const MaterialApp(home: ListaPage()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('0 itens'), findsNothing);
  });

  testWidgets('filtro de categoria: marca duas, desmarca uma, "Todas" limpa', (t) async {
    var marcadas = <String>{};
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, set) => FiltroCategoria(marcadas: marcadas, onMudar: (m) => set(() => marcadas = m)),
        ),
      ),
    ));
    await t.tap(find.text('Mercearia'));
    await t.pump();
    await t.tap(find.text('Açougue'));
    await t.pump();
    expect(marcadas, {'Mercearia', 'Açougue'});
    await t.tap(find.text('Mercearia'));
    await t.pump();
    expect(marcadas, {'Açougue'});
    await t.tap(find.text('Todas'));
    await t.pump();
    expect(marcadas, isEmpty);
  });
}
