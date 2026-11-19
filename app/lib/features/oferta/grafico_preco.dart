import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';

/// Um período de historico_produto (migration 29 do privado): dias seguidos com o mesmo preço num mercado.
class PeriodoPreco {
  PeriodoPreco.fromJson(Map<String, dynamic> j)
      : redeSlug = j['rede_slug'] as String,
        redeNome = j['rede_nome'] as String,
        inicio = DateTime.parse(j['dia_inicio'] as String),
        fim = DateTime.parse(j['dia_fim'] as String),
        preco = (j['preco'] as num).toDouble();

  final String redeSlug, redeNome;
  final DateTime inicio, fim;

  // shortcut: só o preço para todos (o de clube fica de fora); mostrar a linha do clube se o dev pedir.
  final double preco;
}

/// Menor preço dos últimos 30 dias (contando hoje) e onde; nulo sem período nesse intervalo.
({double preco, String mercado})? menorEm30Dias(List<PeriodoPreco> periodos, DateTime hoje) {
  final desde = DateUtils.dateOnly(hoje).subtract(const Duration(days: 29));
  PeriodoPreco? menor;
  for (final p in periodos) {
    if (!p.fim.isBefore(desde) && (menor == null || p.preco < menor.preco)) menor = p;
  }
  return menor == null ? null : (preco: menor.preco, mercado: menor.redeNome);
}

/// Só vale desenhar com 2 dias ou mais: com 1 dia é um ponto, não diz nada.
bool temHistorico(List<PeriodoPreco> periodos) =>
    periodos.isNotEmpty &&
    periodos.map((p) => p.fim).reduce((a, b) => a.isAfter(b) ? a : b).difference(
            periodos.map((p) => p.inicio).reduce((a, b) => a.isBefore(b) ? a : b)) >=
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
      if (mounted) setState(() => _periodos = [for (final j in r as List) PeriodoPreco.fromJson(j as Map<String, dynamic>)]);
    }, onError: (_) {}); // sem histórico ou sem internet: o cartão não aparece
  }

  @override
  Widget build(BuildContext context) =>
      temHistorico(_periodos) ? CartaoGraficoPreco(_periodos, hoje: DateTime.now()) : const SizedBox.shrink();
}

class CartaoGraficoPreco extends StatelessWidget {
  const CartaoGraficoPreco(this.periodos, {super.key, required this.hoje});
  final List<PeriodoPreco> periodos;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final secundario = TextStyle(fontSize: 13, color: c.onSurfaceVariant);
    final menor = menorEm30Dias(periodos, hoje);
    final mercados = {for (final p in periodos) p.redeSlug: p.redeNome};
    final inicio = periodos.map((p) => p.inicio).reduce((a, b) => a.isBefore(b) ? a : b);
    final fim = periodos.map((p) => p.fim).reduce((a, b) => a.isAfter(b) ? a : b);
    final precos = periodos.map((p) => p.preco);
    final minimo = precos.reduce((a, b) => a < b ? a : b), maximo = precos.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Text('Como o preço variou', style: fredoka(18)),
            if (menor != null)
              Text('Menor preço em 30 dias: ${reais(menor.preco)} no ${menor.mercado}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            Semantics(
              container: true,
              label: 'Gráfico do preço de ${diaMes(inicio)} a ${diaMes(fim)}: de ${reais(minimo)} a ${reais(maximo)}',
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: CustomPaint(painter: _Pintor(periodos, inicio, fim, minimo, maximo, c.outlineVariant, c.onSurfaceVariant)),
              ),
            ),
            Row(children: [
              Text(diaMes(inicio), style: secundario),
              const Spacer(),
              Text(diaMes(fim), style: secundario),
            ]),
            Wrap(spacing: 12, runSpacing: 4, children: [
              for (final MapEntry(key: slug, value: nome) in mercados.entries)
                Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Mercado.de(slug).cor, shape: BoxShape.circle)),
                  Text(nome, style: secundario),
                ]),
            ]),
            Text('Espaço em branco: o produto não estava em oferta naquele mercado.', style: secundario),
          ]),
        ),
      ),
    );
  }
}

/// Linha em degraus por mercado: cada período é um trecho reto; períodos colados se ligam por um degrau.
/// Rótulos de preço (máximo em cima, mínimo embaixo) à esquerda.
class _Pintor extends CustomPainter {
  _Pintor(this.periodos, this.inicio, this.fim, this.minimo, this.maximo, this.corGrade, this.corTexto);
  final List<PeriodoPreco> periodos;
  final DateTime inicio, fim;
  final double minimo, maximo;
  final Color corGrade, corTexto;

  @override
  void paint(Canvas canvas, Size size) {
    const margemEsq = 64.0, folga = 8.0;
    final dias = fim.difference(inicio).inDays + 1; // o último dia também ocupa espaço
    double x(DateTime d) => margemEsq + (size.width - margemEsq) * d.difference(inicio).inDays / dias;
    final faixa = maximo - minimo;
    double y(double preco) =>
        faixa == 0 ? size.height / 2 : folga + (size.height - 2 * folga) * (maximo - preco) / faixa;

    final grade = Paint()..color = corGrade..strokeWidth = 1;
    for (final v in {maximo, minimo}) {
      canvas.drawLine(Offset(margemEsq, y(v)), Offset(size.width, y(v)), grade);
      final t = TextPainter(
          text: TextSpan(text: reais(v), style: TextStyle(fontSize: 12, color: corTexto)),
          textDirection: TextDirection.ltr)
        ..layout();
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
  }

  @override
  bool shouldRepaint(_Pintor velho) => velho.periodos != periodos || velho.corGrade != corGrade || velho.corTexto != corTexto;
}
