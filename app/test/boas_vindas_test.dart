import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/features/boas_vindas/boas_vindas.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget app({bool mostrar = true}) => MaterialApp(home: BoasVindas(mostrar: mostrar, child: const Text('Início')));

  testWidgets('três telas com Próximo e Começar; depois fica guardado', (t) async {
    SharedPreferences.setMockInitialValues({});
    expect(await primeiraVez(), isTrue);
    await t.pumpWidget(app());
    expect(find.text(BoasVindas.telas.first.$2), findsOneWidget);
    await t.tap(find.text('Próximo'));
    await t.pumpAndSettle();
    await t.tap(find.text('Próximo'));
    await t.pumpAndSettle();
    expect(find.text(BoasVindas.telas.last.$2), findsOneWidget);
    await t.tap(find.text('Começar'));
    await t.pumpAndSettle();
    expect(find.text('Próximo'), findsNothing);
    expect(find.text('Início'), findsOneWidget);
    expect(await primeiraVez(), isFalse);
  });

  testWidgets('leitor de tela não lê o app escondido atrás', (t) async {
    final semantica = t.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(app());
    expect(find.bySemanticsLabel('Início'), findsNothing);
    await t.tap(find.text('Pular'));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Início'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('Pular fecha de qualquer tela', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(app());
    await t.tap(find.text('Pular'));
    await t.pumpAndSettle();
    expect(find.text(BoasVindas.telas.first.$2), findsNothing);
  });

  testWidgets('quem já usava o app (algo guardado) não vê', (t) async {
    SharedPreferences.setMockInitialValues({'cache_inicio': '[]'});
    expect(await primeiraVez(), isFalse);
    await t.pumpWidget(app(mostrar: false));
    expect(find.text('Pular'), findsNothing);
  });
}
