import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/config.dart';
import '../../core/formato.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
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

/// Espaço de anúncio: o vendido pelo dev (selo "Patrocinado"); senão a rede do Google (AdSense no web, AdMob no
/// celular) ou "Anuncie aqui", com o selo "Anúncio".
class EspacoAnuncioView extends StatelessWidget {
  const EspacoAnuncioView({super.key, this.anuncio, required this.espaco, this.alturaRede = 100});
  final Anuncio? anuncio;

  /// Onde está, para o Analytics: inicio, mercado, oferta ou busca.
  final String espaco;
  final double alturaRede;

  @override
  Widget build(BuildContext context) {
    final a = anuncio;
    // "quantos viram", para o anunciante: o build roda quando o espaço entra na tela (listas são preguiçosas)
    if (a != null) eventoUmaVezPorTela('anuncio_visto', '$espaco:${a.id}', {'anuncio_id': a.id, 'espaco': espaco});
    final cartao = _cartao(context, a, a == null ? 'Anúncio' : 'Patrocinado');
    return (a == null ? blocoAdsense(alturaRede, selo: const SeloAnuncio(), reserva: cartao) : null) ?? cartao;
  }

  Widget _cartao(BuildContext context, Anuncio? a, String selo) {
    // contatoAnuncie é da config do dev (mailto: no prod); o link do anúncio vem do banco e só abre se for https
    final uri = a == null ? Uri.tryParse(contatoAnuncie) : linkDoAnuncio(a.linkUrl);
    return Semantics(
      container: true,
      label: selo,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: uri == null
              ? null
              : () {
                  if (a != null) evento('anuncio_clique', {'anuncio_id': a.id, 'espaco': espaco});
                  launchUrl(uri);
                },
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
                    // limites do Guia do Anunciante (privado: docs/guia-do-anunciante.md): título até 40, texto até 80 caracteres
                    Text(a?.titulo ?? 'Anuncie aqui',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(a?.texto ?? 'Seu comércio para quem está fazendo as compras em Governador Valadares.',
                        maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.cores.onSurfaceVariant)),
                  ]),
                ),
              ]),
              if (a?.cupomCodigo != null || a?.cupomRegra != null) _Cupom(a!),
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

/// Cupom do comércio local: código (toque copia), regra e validade (o fim do anúncio).
class _Cupom extends StatelessWidget {
  const _Cupom(this.a);
  final Anuncio a;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final codigo = a.cupomCodigo;
    final detalhe = [a.cupomRegra, if (a.fim != null) 'até ${diaMes(a.fim!)}'].whereType<String>().join(' · ');
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
          color: c.secondaryContainer, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.outlineVariant)),
      child: Row(children: [
        Icon(Icons.local_offer_outlined, size: 18, color: c.onSecondaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (codigo != null)
              Text('Cupom $codigo', style: TextStyle(fontWeight: FontWeight.w800, color: c.onSecondaryContainer)),
            if (detalhe.isNotEmpty)
              Text(detalhe, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.onSecondaryContainer)),
          ]),
        ),
        if (codigo != null)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codigo));
              evento('cupom_copiado', {'anuncio_id': a.id});
              avisar(context, 'Cupom $codigo copiado', verLista: false);
            },
            child: const Text('Copiar'),
          ),
      ]),
    );
  }
}
