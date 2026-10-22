import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/features/lista/grupos.dart';
import 'package:promocao_na_mao/features/lista/lista.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Carrega extends StatefulWidget {
  const _Carrega(this.lista);
  final Lista lista;

  @override
  State<_Carrega> createState() => _CarregaState();
}

class _CarregaState extends State<_Carrega> {
  @override
  void initState() {
    super.initState();
    widget.lista.carregar(); // como a aba Lista faz
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

ItemLista _item(int qtd, double? preco, [double? clube]) => ItemLista.fromJson(
    {'id': 1, 'texto': 'x', 'quantidade': qtd, 'pego': false, 'preco': preco, 'preco_clube': clube});

void main() {
  test('total do mercado: preço × quantidade, clube quando tem, anotados fora', () {
    expect(totalDoMercado([_item(2, 4.5), _item(1, null)]), (9.0, null));
    expect(totalDoMercado([_item(2, 4.5, 4.0), _item(1, 3.0)]), (12.0, 11.0));
  });


  // Crashlytics (0.1.0): "setState() or markNeedsBuild() called during build ... dispatching notifications for Lista".
  testWidgets('carregar no initState não avisa no meio do build', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final lista = Lista.recebida('codigo-de-teste'); // sem Supabase: cai no "sem internet"
    // Como no app: o contador da lista já está na tela; depois só a aba muda (outro pedaço da árvore) e abre a Lista.
    var aba = false;
    late StateSetter trocar;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        ListenableBuilder(listenable: lista, builder: (_, _) => Text(lista.carregando ? 'carregando' : 'pronto')),
        StatefulBuilder(builder: (_, s) {
          trocar = s;
          return aba ? _Carrega(lista) : const SizedBox();
        }),
      ]),
    ));
    trocar(() => aba = true);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(lista.erro, isTrue);
  });
}
