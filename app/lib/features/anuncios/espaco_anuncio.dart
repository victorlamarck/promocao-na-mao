import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import 'admob.dart' if (dart.library.js_interop) 'adsense_web.dart';
import 'anuncios.dart';

/// Selo obrigatório em tudo que é pago (docs/design.md, "Anúncios").
class SeloAnuncio extends StatelessWidget {
  const SeloAnuncio({super.key, this.texto = 'Anúncio'});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: context.cores.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cores.onTertiaryContainer)),
      );
}

/// Espaço de anúncio: o vendido pelo dev; senão a rede do Google (AdSense no web, AdMob no Android); senão "Anuncie aqui".
class EspacoAnuncioView extends StatelessWidget {
  const EspacoAnuncioView({super.key, this.anuncio, this.selo = 'Anúncio', this.alturaRede = 100});
  final Anuncio? anuncio;
  final String selo;
  final double alturaRede;

  @override
  Widget build(BuildContext context) {
    final a = anuncio;
    final cartao = _cartao(context, a);
    return (a == null ? blocoAdsense(alturaRede, selo: SeloAnuncio(texto: selo), reserva: cartao) : null) ?? cartao;
  }

  Widget _cartao(BuildContext context, Anuncio? a) {
    // contatoAnuncie é da config do dev (mailto: no prod); o link do anúncio vem do banco e só abre se for https
    final uri = a == null ? Uri.tryParse(contatoAnuncie) : linkDoAnuncio(a.linkUrl);
    return Semantics(
      container: true,
      label: selo,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: uri == null ? null : () => launchUrl(uri),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SeloAnuncio(texto: selo),
              const SizedBox(height: 8),
              Row(children: [
                if (a?.imagemUrl != null) ...[
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(a!.imagemUrl!, width: 64, height: 64, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(width: 64, height: 64))),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a?.titulo ?? 'Anuncie aqui', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(a?.texto ?? 'Seu comércio para quem está fazendo as compras em Governador Valadares.',
                        style: TextStyle(fontSize: 13, color: context.cores.onSurfaceVariant)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Text(a == null ? 'Quero anunciar' : 'Saiba mais',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.cores.primary)),
            ]),
          ),
        ),
      ),
    );
  }
}
