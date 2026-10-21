import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/abertura.dart';

void main() {
  Widget app({bool pular = false, bool semAnimacao = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: semAnimacao),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Abertura(pular: pular, child: const Text('Início')),
        ),
      );

  testWidgets('cobre o app e some em 1 s', (t) async {
    await t.pumpWidget(app());
    expect(find.byType(CustomPaint), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1100));
    expect(find.byType(CustomPaint), findsNothing);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('aberto por link ou com menos movimento: sem animação', (t) async {
    await t.pumpWidget(app(pular: true));
    expect(find.byType(CustomPaint), findsNothing);
    await t.pumpWidget(KeyedSubtree(key: UniqueKey(), child: app(semAnimacao: true)));
    expect(find.byType(CustomPaint), findsNothing);
  });
}
