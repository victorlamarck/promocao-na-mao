// Textos do encarte traduzidos para português simples (docs/design.md, "Regras de clareza").

/// 4.99 → "R$ 4,99"; 1234.5 → "R$ 1.234,50".
String reais(double v) {
  final partes = v.toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => '.');
  return 'R\$ $inteiro,${partes[1]}';
}

const _dias = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

String _dd(int n) => n.toString().padLeft(2, '0');

/// "03/11".
String diaMes(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}';

/// "vale até segunda, 03/11".
String valeAte(DateTime fim) => 'Vale até ${_dias[fim.weekday - 1]}, ${diaMes(fim)}';

/// "Atualizado hoje às 08:12" / "ontem às 08:12" / "em 19/10 às 08:12".
String atualizado(DateTime quando, DateTime agora) {
  final n = DateTime(agora.year, agora.month, agora.day).difference(DateTime(quando.year, quando.month, quando.day)).inDays;
  final dia = switch (n) { 0 => 'hoje', 1 => 'ontem', _ => 'em ${diaMes(quando)}' };
  return 'Atualizado $dia às ${_dd(quando.hour)}:${_dd(quando.minute)}';
}

/// "Vence hoje" / "Falta 1 dia" / "Faltam 16 dias".
// shortcut: "hoje" vem do relógio do aparelho, não do fuso de Brasília; só difere fora do Brasil.
String faltam(DateTime fim, DateTime hoje) {
  final n = DateTime(fim.year, fim.month, fim.day).difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  return switch (n) { <= 0 => 'Vence hoje', 1 => 'Falta 1 dia', _ => 'Faltam $n dias' };
}

/// Selo do card e da lista: "Vence hoje", "Vence amanhã", "Encarte venceu"; null quando falta mais.
String? avisoValidade(DateTime fim, DateTime hoje) {
  final n = DateTime(fim.year, fim.month, fim.day).difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  return n < 0 ? 'Encarte venceu' : switch (n) { 0 => 'Vence hoje', 1 => 'Vence amanhã', _ => null };
}

/// "R$ 4,76 o kg" / "R$ 1,99 o litro"; null por unidade ("cada") ou quando repete o [preco] exibido (mesma regra do site).
String? porUnidade(double? valor, String? unidade, {double? preco}) => valor == null || valor == preco
    ? null
    : switch (unidade) { 'kg' => '${reais(valor)} o kg', 'l' => '${reais(valor)} o litro', _ => null };
