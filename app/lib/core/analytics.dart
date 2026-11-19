import 'package:firebase_analytics/firebase_analytics.dart';

/// Evento de ação no Firebase Analytics (docs/app.md#crashlytics-e-analytics). Sem Firebase (testes) não conta.
void evento(String nome, [Map<String, Object>? parametros]) {
  try {
    FirebaseAnalytics.instance.logEvent(name: nome, parameters: parametros).ignore();
  } catch (_) {}
}

final _contadosNestaTela = <String>{};

/// Zera a conta de [eventoUmaVezPorTela]; o main.dart chama a cada troca de tela.
void novaTela() => _contadosNestaTela.clear();

/// Para o que é contado ao aparecer (o build roda de novo ao rolar a lista): só a 1ª vez por [chave] em cada tela.
/// Devolve se contou.
bool eventoUmaVezPorTela(String nome, String chave, [Map<String, Object>? parametros]) {
  if (!_contadosNestaTela.add('$nome:$chave')) return false;
  evento(nome, parametros);
  return true;
}
