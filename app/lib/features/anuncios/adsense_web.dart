import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../../core/config.dart';

bool get _ativo => adsenseCliente.isNotEmpty && adsenseSlot.isNotEmpty;

/// Carrega o script do AdSense uma vez (só com ADSENSE_CLIENT e ADSENSE_SLOT definidos).
void iniciarAdsense() {
  if (!_ativo) return;
  final s = web.document.createElement('script') as web.HTMLScriptElement
    ..async = true
    ..crossOrigin = 'anonymous'
    ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=$adsenseCliente';
  web.document.head!.append(s);
}

var _proximo = 0;

/// Um bloco do AdSense (elemento <ins> do Google dentro do Flutter web), com o [selo] em cima.
/// A [reserva] é do celular (AdMob sem anúncio); no web o AdSense ocupa o espaço mesmo vazio.
// shortcut: não testado sem conta AdSense aprovada; validar quando o dev tiver o ca-pub e o slot.
Widget? blocoAdsense(double altura, {required Widget selo, required Widget reserva}) {
  if (!_ativo) return null;
  final tipo = 'adsense-${_proximo++}';
  ui_web.platformViewRegistry.registerViewFactory(tipo, (int _) {
    final caixa = web.document.createElement('div') as web.HTMLDivElement;
    final ins = web.document.createElement('ins') as web.HTMLElement
      ..className = 'adsbygoogle'
      ..setAttribute('style', 'display:block;width:100%;height:${altura}px')
      ..setAttribute('data-ad-client', adsenseCliente)
      ..setAttribute('data-ad-slot', adsenseSlot);
    final pedir = web.document.createElement('script') as web.HTMLScriptElement
      ..text = '(window.adsbygoogle = window.adsbygoogle || []).push({});';
    caixa
      ..append(ins)
      ..append(pedir);
    return caixa;
  });
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    selo,
    const SizedBox(height: 6),
    SizedBox(height: altura, child: HtmlElementView(viewType: tipo)),
  ]);
}
