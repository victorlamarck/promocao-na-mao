import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics.dart';

/// Pedido de avaliação nas lojas (t14): o pedido nativo da Play e da App Store, depois de um momento bom
/// (compartilhou a lista ou viu quanto ela sai em cada mercado). Nunca na 1ª abertura e no máximo 1 vez a cada
/// [intervaloDias]; as lojas ainda limitam por conta própria quantas vezes a janela aparece de fato.
const intervaloDias = 90;
const _aberturas = 'aberturas', _pedidoEm = 'avaliacao_pedida_em';

/// Conta uma abertura do app (main.dart).
Future<void> contarAbertura() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_aberturas, (prefs.getInt(_aberturas) ?? 0) + 1);
}

/// A regra, sem o celular: da 2ª abertura em diante e longe do último pedido.
bool devePedirAvaliacao({required int aberturas, DateTime? ultimoPedido, required DateTime agora}) =>
    aberturas >= 2 && (ultimoPedido == null || agora.difference(ultimoPedido).inDays >= intervaloDias);

/// Chamar no momento bom; [momento] vai para o Analytics (compartilhou, comparacao).
Future<void> pedirAvaliacao(String momento) async {
  if (kIsWeb) return; // só app de loja
  try {
    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getInt(_pedidoEm);
    if (!devePedirAvaliacao(
        aberturas: prefs.getInt(_aberturas) ?? 0,
        ultimoPedido: ultimo == null ? null : DateTime.fromMillisecondsSinceEpoch(ultimo),
        agora: DateTime.now())) {
      return;
    }
    final loja = InAppReview.instance;
    if (!await loja.isAvailable()) return;
    await prefs.setInt(_pedidoEm, DateTime.now().millisecondsSinceEpoch);
    evento('avaliacao_pedida', {'momento': momento});
    await loja.requestReview();
  } catch (_) {} // avaliação nunca derruba nada
}
