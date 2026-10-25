import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/rotas.dart';
import 'package:promocao_na_mao/features/busca/busca_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // sem banco de verdade: no teste toda chamada HTTP volta 400 e as telas mostram o erro/vazio
    await Supabase.initialize(url: 'http://localhost', publishableKey: 'teste');
  });

  testWidgets('trocar de aba e voltar: a Busca guarda o texto e não reabre o teclado', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: rotas));
    await t.pump();

    await t.tap(find.text('Buscar'));
    await t.pumpAndSettle();
    final campo = find.widgetWithText(TextField, 'Buscar: arroz, café, cerveja…');
    await t.enterText(campo, 'arroz');
    await t.pumpAndSettle(const Duration(milliseconds: 500));

    await t.tap(find.text('Mercados'));
    await t.pumpAndSettle();
    expect(t.testTextInput.isVisible, isFalse); // a aba escondida soltou o teclado

    await t.tap(find.text('Buscar'));
    await t.pumpAndSettle();
    expect(find.text('arroz'), findsOneWidget);
    expect(t.testTextInput.isVisible, isFalse); // autofocus só na primeira vez

    // detalhe abre por cima das abas; o voltar devolve a Busca como estava
    rotas.push('/oferta/1');
    await t.pumpAndSettle();
    expect(find.text('Oferta'), findsOneWidget);
    rotas.pop();
    await t.pumpAndSettle();
    expect(find.text('arroz'), findsOneWidget);

    // a busca da Início leva para a aba Buscar já com o teclado
    await t.tap(find.text('Início'));
    await t.pumpAndSettle();
    await t.tap(find.byType(SearchBar));
    await t.pumpAndSettle();
    expect(find.text('arroz'), findsOneWidget);
    expect(BuscaPage.foco.hasFocus, isTrue);
  });
}
