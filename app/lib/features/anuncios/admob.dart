import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config.dart';

// Celular: o AdSense não roda em app; a rede do Google aqui é o AdMob (mesmos anunciantes e pagamento).
// shortcut: só Android; o iPhone precisa do GADApplicationIdentifier de verdade no Info.plist e do
// SKAdNetwork, quando o app de iPhone for para a loja.
bool get _ativo => !kIsWeb && defaultTargetPlatform == TargetPlatform.android && admobBloco.isNotEmpty;

void iniciarAdsense() {
  if (_ativo) MobileAds.instance.initialize();
}

/// Espaço sem anúncio vendido: bloco do AdMob com o selo; se o Google não tiver anúncio, a [reserva] ("Anuncie aqui").
Widget? blocoAdsense(double altura, {required Widget selo, required Widget reserva}) =>
    _ativo ? _BlocoAdmob(selo: selo, reserva: reserva) : null;

class _BlocoAdmob extends StatefulWidget {
  const _BlocoAdmob({required this.selo, required this.reserva});
  final Widget selo, reserva;

  @override
  State<_BlocoAdmob> createState() => _BlocoAdmobState();
}

class _BlocoAdmobState extends State<_BlocoAdmob> {
  late final BannerAd _anuncio;
  var _pronto = false, _falhou = false;

  @override
  void initState() {
    super.initState();
    _anuncio = BannerAd(
      adUnitId: admobBloco,
      size: AdSize.largeBanner, // 320×100: o tamanho do espaço no feed
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _pronto = true) : null,
        onAdFailedToLoad: (_, _) => mounted ? setState(() => _falhou = true) : null,
      ),
    )..load();
  }

  @override
  void dispose() {
    _anuncio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _falhou
      ? widget.reserva
      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          widget.selo,
          const SizedBox(height: 6),
          // Altura reservada desde o começo: a lista não pula quando o anúncio chega.
          Center(child: SizedBox(width: 320, height: 100, child: _pronto ? AdWidget(ad: _anuncio) : null)),
        ]);
}
