import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import 'dica.dart';

/// Um período de historico_produto (migration 29 do privado): dias seguidos com o mesmo preço num mercado.
class PeriodoPreco {
  PeriodoPreco.fromJson(Map<String, dynamic> j)
    : redeSlug = j['rede_slug'] as String,
      redeNome = j['rede_nome'] as String,
      inicio = DateTime.parse(j['dia_inicio'] as String),
      fim = DateTime.parse(j['dia_fim'] as String),
      preco = (j['preco'] as num).toDouble();

  PeriodoPreco._(this.redeSlug, this.redeNome, this.inicio, this.fim, this.preco);

  PeriodoPreco cortado(DateTime desde, DateTime ate) =>
      PeriodoPreco._(redeSlug, redeNome, inicio.isBefore(desde) ? desde : inicio, fim.isAfter(ate) ? ate : fim, preco);

  final String redeSlug, redeNome;
  final DateTime inicio, fim;

  // shortcut: só o preço para todos (o de clube fica de fora); mostrar a linha do clube se o dev pedir.
  final double preco;
}

/// Períodos dos últimos [dias] dias (contando hoje), cortados para caber nessa janela.
List<PeriodoPreco> recorte(List<PeriodoPreco> periodos, DateTime hoje, int dias) {
  final ate = DateUtils.dateOnly(hoje), desde = ate.subtract(Duration(days: dias - 1));
  return [
    for (final p in periodos)
      if (!p.fim.isBefore(desde) && !p.inicio.isAfter(ate)) p.cortado(desde, ate),
  ];
}

/// Menor preço dos últimos [dias] dias (contando hoje) e onde; nulo sem período nesse intervalo.
({double preco, String mercado})? menorEm(List<PeriodoPreco> periodos, DateTime hoje, int dias) {
  PeriodoPreco? menor;
  for (final p in recorte(periodos, hoje, dias)) {
    if (menor == null || p.preco < menor.preco) menor = p;
  }
  return menor == null ? null : (preco: menor.preco, mercado: menor.redeNome);
}

/// Preço de cada mercado num dia (nome → preço), do mais barato ao mais caro; sem oferta naquele dia fica de fora.
Map<String, double> precosNoDia(List<PeriodoPreco> periodos, DateTime dia) => Map.fromEntries(
  [
    for (final p in periodos)
      if (!dia.isBefore(p.inicio) && !dia.isAfter(p.fim)) MapEntry(p.redeNome, p.preco),
  ]..sort((a, b) => a.value.compareTo(b.value)),
);

/// Último dia do gráfico: hoje, ou ontem enquanto o dia de hoje não foi gravado (o histórico é gravado às 23:50).
DateTime ultimoDia(List<PeriodoPreco> periodos, DateTime agora) {
  final hoje = DateUtils.dateOnly(agora);
  return periodos.any((p) => !p.fim.isBefore(hoje)) ? hoje : hoje.subtract(const Duration(days: 1));
}

/// Só vale desenhar com 2 dias ou mais: com 1 dia é um ponto, não diz nada.
bool temHistorico(List<PeriodoPreco> periodos) =>
    periodos.isNotEmpty &&
    periodos
            .map((p) => p.fim)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .difference(periodos.map((p) => p.inicio).reduce((a, b) => a.isBefore(b) ? a : b)) >=
        const Duration(days: 1);

/// Cartão "Como o preço variou" da tela da oferta: busca o histórico do produto e some se não houver o que mostrar.
class GraficoPreco extends StatefulWidget {
  const GraficoPreco({super.key, required this.produtoId});
  final int produtoId;

  @override
  State<GraficoPreco> createState() => _GraficoPrecoState();
}

class _GraficoPrecoState extends State<GraficoPreco> {
  List<PeriodoPreco> _periodos = const [];

  @override
  void initState() {
    super.initState();
    Supabase.instance.client.rpc('historico_produto', params: {'produto_id': widget.produtoId}).then((r) {
      if (mounted) {
        setState(() => _periodos = [for (final j in r as List) PeriodoPreco.fromJson(j as Map<String, dynamic>)]);
      }
    }, onError: (_) {}); // sem histórico ou sem internet: o cartão não aparece
  }

  @override
  Widget build(BuildContext context) => temHistorico(_periodos)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // a dica só nasce quando o gráfico aparece: é a "1ª vez que o gráfico aparece"
            const Dica(
              id: 'grafico',
              icone: Icons.show_chart,
              texto: 'Novo: veja aqui como o preço deste produto variou nos últimos dias em cada mercado.',
              margem: EdgeInsets.only(top: 12),
            ),
            CartaoGraficoPreco(_periodos, hoje: DateTime.now()),
          ],
        )
      : const SizedBox.shrink();
}

/// Cartão com os períodos 7D, 15D, 30D e 90D (como os gráficos de cotação): tocar ou arrastar o dedo no gráfico
/// mostra o preço de cada mercado naquele dia.
class CartaoGraficoPreco extends StatefulWidget {
  const CartaoGraficoPreco(this.periodos, {super.key, required this.hoje});
  final List<PeriodoPreco> periodos;
  final DateTime hoje;

  @override
  State<CartaoGraficoPreco> createState() => _CartaoGraficoPrecoState();
}

class _CartaoGraficoPrecoState extends State<CartaoGraficoPreco> {
  static const _opcoes = [7, 15, 30, 90]; // 90 = tudo o que historico_produto devolve
  var _dias = 30;
  DateTime? _dia; // dia tocado no gráfico

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final secundario = TextStyle(fontSize: 13, color: c.onSurfaceVariant);
    final hoje = ultimoDia(widget.periodos, widget.hoje);
    final inicio = hoje.subtract(Duration(days: _dias - 1));
    final periodos = recorte(widget.periodos, hoje, _dias);
    final menor = menorEm(widget.periodos, hoje, _dias);
    final mercados = {for (final p in widget.periodos) p.redeSlug: p.redeNome};
    final precos = periodos.map((p) => p.preco);
    final minimo = precos.isEmpty ? 0.0 : precos.reduce((a, b) => a < b ? a : b);
    final maximo = precos.isEmpty ? 0.0 : precos.reduce((a, b) => a > b ? a : b);

    void tocar(Offset ponto, double largura) {
      final i = ((ponto.dx - _Pintor.margemEsq) / (largura - _Pintor.margemEsq) * _dias).floor().clamp(0, _dias - 1);
      setState(() => _dia = inicio.add(Duration(days: i)));
    }

    final dia = _dia;
    final noDia = dia == null ? null : precosNoDia(periodos, dia);
    final destaque = noDia != null && dia != null
        ? (noDia.isEmpty
              ? '${diaMes(dia)}: sem oferta deste produto'
              : '${diaMes(dia)}: ${[for (final MapEntry(key: m, value: v) in noDia.entries) '$m ${reais(v)}'].join(' · ')}')
        : menor != null
        ? 'Menor preço em $_dias dias: ${reais(menor.preco)} no ${menor.mercado}'
        : 'Sem oferta deste produto nos últimos $_dias dias.';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Como o preço variou', style: fredoka(18)),
              SegmentedButton<int>(
                segments: [
                  for (final d in _opcoes) ButtonSegment(value: d, label: Text('${d}D'), tooltip: 'Últimos $d dias'),
                ],
                selected: {_dias},
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onSelectionChanged: (s) => setState(() {
                  _dias = s.first;
                  _dia = null;
                }),
              ),
              Text(destaque, style: const TextStyle(fontWeight: FontWeight.w700)),
              Semantics(
                container: true,
                label: periodos.isEmpty
                    ? 'Gráfico vazio de ${diaMes(inicio)} a ${diaMes(hoje)}'
                    : 'Gráfico do preço de ${diaMes(inicio)} a ${diaMes(hoje)}: de ${reais(minimo)} a ${reais(maximo)}',
                child: LayoutBuilder(
                  builder: (context, caixa) => GestureDetector(
                    onTapDown: (d) => tocar(d.localPosition, caixa.maxWidth),
                    onHorizontalDragStart: (d) => tocar(d.localPosition, caixa.maxWidth),
                    onHorizontalDragUpdate: (d) => tocar(d.localPosition, caixa.maxWidth),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _Pintor(
                          periodos,
                          inicio,
                          hoje,
                          minimo,
                          maximo,
                          c.outlineVariant,
                          c.onSurfaceVariant,
                          c.onSurface,
                          dia,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(diaMes(inicio), style: secundario),
                  const Spacer(),
                  Text(diaMes(hoje), style: secundario),
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final MapEntry(key: slug, value: nome) in mercados.entries)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: Mercado.de(slug).cor, shape: BoxShape.circle),
                        ),
                        Text(nome, style: secundario),
                      ],
                    ),
                ],
              ),
              Text(
                'Toque no gráfico para ver o preço do dia. Espaço em branco: o produto não estava em oferta naquele mercado.',
                style: secundario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha em degraus por mercado: cada período é um trecho reto; períodos colados se ligam por um degrau.
/// Rótulos de preço (máximo em cima, mínimo embaixo) à esquerda.
class _Pintor extends CustomPainter {
  _Pintor(
    this.periodos,
    this.inicio,
    this.fim,
    this.minimo,
    this.maximo,
    this.corGrade,
    this.corTexto,
    this.corMarca,
    this.dia,
  );
  final List<PeriodoPreco> periodos;
  final DateTime inicio, fim;
  final double minimo, maximo;
  final Color corGrade, corTexto, corMarca;
  final DateTime? dia;
  static const margemEsq = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    const folga = 8.0;
    final dias = fim.difference(inicio).inDays + 1; // o último dia também ocupa espaço
    double x(DateTime d) => margemEsq + (size.width - margemEsq) * d.difference(inicio).inDays / dias;
    final faixa = maximo - minimo;
    double y(double preco) =>
        faixa == 0 ? size.height / 2 : folga + (size.height - 2 * folga) * (maximo - preco) / faixa;

    final grade = Paint()
      ..color = corGrade
      ..strokeWidth = 1;
    if (periodos.isEmpty) {
      canvas.drawLine(Offset(margemEsq, size.height / 2), Offset(size.width, size.height / 2), grade);
      return;
    }
    for (final v in {maximo, minimo}) {
      canvas.drawLine(Offset(margemEsq, y(v)), Offset(size.width, y(v)), grade);
      final t = TextPainter(
        text: TextSpan(
          text: reais(v),
          style: TextStyle(fontSize: 12, color: corTexto),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(0, y(v) - t.height / 2));
    }

    final porMercado = <String, List<PeriodoPreco>>{};
    for (final p in periodos) {
      (porMercado[p.redeSlug] ??= []).add(p);
    }
    for (final MapEntry(key: slug, value: lista) in porMercado.entries) {
      final tinta = Paint()
        ..color = Mercado.de(slug).cor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      lista.sort((a, b) => a.inicio.compareTo(b.inicio));
      PeriodoPreco? antes;
      for (final p in lista) {
        final ate = p.fim.add(const Duration(days: 1));
        if (antes != null && antes.fim.add(const Duration(days: 1)) == p.inicio) {
          canvas.drawLine(Offset(x(p.inicio), y(antes.preco)), Offset(x(p.inicio), y(p.preco)), tinta);
        }
        canvas.drawLine(Offset(x(p.inicio), y(p.preco)), Offset(x(ate), y(p.preco)), tinta);
        antes = p;
      }
    }

    // dia tocado: linha vertical no meio do dia e uma bolinha em cada mercado com oferta nele
    final d = dia;
    if (d != null) {
      final meio = x(d) + (x(d.add(const Duration(days: 1))) - x(d)) / 2;
      canvas.drawLine(
        Offset(meio, 0),
        Offset(meio, size.height),
        Paint()
          ..color = corMarca.withValues(alpha: .5)
          ..strokeWidth = 1.5,
      );
      for (final p in periodos) {
        if (d.isBefore(p.inicio) || d.isAfter(p.fim)) continue;
        final centro = Offset(meio, y(p.preco));
        canvas.drawCircle(centro, 5, Paint()..color = Mercado.de(p.redeSlug).cor);
        canvas.drawCircle(
          centro,
          5,
          Paint()
            ..color = corMarca
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Pintor velho) =>
      velho.periodos != periodos || velho.dia != dia || velho.corGrade != corGrade || velho.corTexto != corTexto;
}
