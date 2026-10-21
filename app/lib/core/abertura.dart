import 'dart:math';

import 'package:flutter/material.dart';

/// Animação de abertura por cima do app: continua a tela nativa (mesmo verde, etiqueta branca sem sorriso
/// e mesma escala: 48 unidades = 192 dp, como o abertura.png da tela nativa),
/// a etiqueta balança pendurada pelo furo, o sorriso se desenha e tudo some. ~1 s no total,
/// enquanto as ofertas já carregam por baixo. Sem animação se o sistema pediu menos movimento.
class Abertura extends StatefulWidget {
  const Abertura({super.key, required this.child, this.pular = false});
  final Widget child;

  /// Abriu por link (lista, oferta): vai direto para a tela.
  final bool pular;

  static const verde = Color(0xFF1E7A66);

  @override
  State<Abertura> createState() => _AberturaState();
}

class _AberturaState extends State<Abertura> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late var _visivel = !widget.pular;

  @override
  void initState() {
    super.initState();
    if (_visivel) _anim.forward().whenComplete(() => mounted ? setState(() => _visivel = false) : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visivel && MediaQuery.maybeDisableAnimationsOf(context) == true) _visivel = false;
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (_visivel)
          AnimatedBuilder(
            animation: _anim,
            builder: (_, _) {
              final t = _anim.value;
              final sumir = Curves.easeIn.transform(((t - .7) / .3).clamp(0, 1));
              return IgnorePointer(
                child: Opacity(
                  opacity: 1 - sumir,
                  child: ColoredBox(
                    color: Abertura.verde,
                    child: Center(
                      child: Transform.scale(
                        scale: 1 + .15 * sumir,
                        child: CustomPaint(size: const Size.square(192), painter: _Etiqueta(t)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ]);
}

/// O símbolo (site/public/favicon.svg, 48×48) invertido: etiqueta branca, olho e sorriso verdes.
class _Etiqueta extends CustomPainter {
  _Etiqueta(this.t);
  final double t;

  static final _corpo = Path()
    ..moveTo(8, 22.5)
    ..lineTo(21.5, 9)
    ..lineTo(37, 9)
    ..lineTo(37, 24.5)
    ..lineTo(23.5, 38)
    ..relativeArcToPoint(const Offset(-4.8, 0), radius: const Radius.circular(3.4))
    ..lineTo(8, 27.3)
    ..relativeArcToPoint(const Offset(0, -4.8), radius: const Radius.circular(3.4))
    ..close();
  static final _sorriso = Path()
    ..moveTo(17, 24)
    ..relativeCubicTo(1.9, 3, 5.4, 4.2, 8.6, 2.8);
  static const _furo = Offset(31, 15);

  /// Balanço amortecido (0–0,7 s) em torno do furo.
  static double angulo(double t) => t >= .7 ? 0 : .28 * sin(t / .7 * 3 * pi) * (1 - t / .7);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);
    canvas
      ..translate(_furo.dx, _furo.dy)
      ..rotate(angulo(t))
      ..translate(-_furo.dx, -_furo.dy);
    canvas.drawPath(_corpo, Paint()..color = Colors.white);
    canvas.drawCircle(_furo, 2.8, Paint()..color = Abertura.verde);
    // sorriso se desenha entre 0,15 e 0,55 s
    final p = ((t - .15) / .4).clamp(0.0, 1.0);
    final m = _sorriso.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * Curves.easeOut.transform(p)),
      Paint()
        ..color = Abertura.verde
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Etiqueta old) => old.t != t;
}
