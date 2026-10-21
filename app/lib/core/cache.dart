import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sem internet (sinal ruim dentro do mercado): devolve a última resposta salva de [chave].
/// Com internet, busca e salva. Sem nada salvo, o erro segue para a tela.
Future<List<Map<String, dynamic>>> comCache(String chave, Future<List<Map<String, dynamic>>> Function() buscar) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    // Sinal ruim: sem tempo limite, o pedido leva de 6 a 16 s para falhar (medido num Pixel em modo avião).
    final linhas = await buscar().timeout(const Duration(seconds: 5));
    // vazio não substitui o salvo (e um slug inventado num link não ocupa espaço)
    if (linhas.isNotEmpty) await prefs.setString('cache_$chave', jsonEncode(linhas));
    return linhas;
  } catch (_) {
    final salvo = prefs.getString('cache_$chave');
    if (salvo == null) rethrow;
    return (jsonDecode(salvo) as List).cast<Map<String, dynamic>>();
  }
}
