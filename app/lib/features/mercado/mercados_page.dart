import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/cache.dart';
import '../../core/config.dart';
import '../../core/formato.dart';
import '../../core/localizacao.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';

final _db = Supabase.instance.client;

/// Mercados com ofertas válidas hoje, do mais perto ao mais longe (sem localização: ordem alfabética).
/// O destaque pago vai primeiro, com selo.
Future<(List<Rede>, Map<int, double>, int?)> mercadosOrdenados() async {
  final redes = (await comCache('redes', () => _db.from('rede_com_ofertas').select().order('nome'))).map(Rede.fromJson).toList();
  final distancias = await distanciaPorRede();
  final destaque = await anunciosDoFormato('mercado_destaque').catchError((_) => <Anuncio>[]); // sem internet: sem destaque
  final id = destaque.isEmpty ? null : destaque.first.redeId;
  double ordem(Rede r) => r.id == id ? -1 : distancias[r.id] ?? 0;
  if (distancias.isNotEmpty || id != null) redes.sort((a, b) => ordem(a).compareTo(ordem(b)));
  return (redes, distancias, id);
}

/// Aba Mercados (tela 3 do protótipo).
class MercadosPage extends StatefulWidget {
  const MercadosPage({super.key});

  @override
  State<MercadosPage> createState() => _MercadosPageState();
}

class _MercadosPageState extends State<MercadosPage> {
  late var _dados = mercadosOrdenados();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mercados')),
        body: FutureBuilder(
          future: _dados,
          builder: (context, s) {
            if (s.hasError) return Erro(onTentar: () => setState(() { _dados = mercadosOrdenados(); }));
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final (redes, distancias, destaque) = s.data!;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              Text(distancias.isEmpty ? 'Ative a localização para ver os mais perto de você' : 'Do mais perto ao mais longe de você',
                  style: TextStyle(fontSize: 14, color: context.cores.onSurfaceVariant)),
              const SizedBox(height: 12),
              for (final r in redes) ...[CardMercado(r, distancia: distancias[r.id], patrocinado: r.id == destaque), const SizedBox(height: 8)],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), border: Border.all(color: context.cores.outline)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                  const Text('Seu mercado não está aqui?', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('Conte pra gente qual encarte você quer ver no app.',
                      style: TextStyle(color: context.cores.onSurfaceVariant)),
                  TextButton(onPressed: () => launchUrl(Uri.parse(contatoSugestao)), child: const Text('Sugerir mercado')),
                ]),
              ),
            ]);
          },
        ),
      );
}

/// Linha de um mercado: sigla, nome, distância, validade do encarte, clube.
class CardMercado extends StatelessWidget {
  const CardMercado(this.rede, {super.key, this.distancia, this.patrocinado = false});
  final Rede rede;
  final double? distancia;
  final bool patrocinado;

  @override
  Widget build(BuildContext context) {
    final clube = Mercado.de(rede.slug).clube;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/mercado/${rede.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(spacing: 16, children: [
            AvatarMercado(rede.slug),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                Row(spacing: 8, children: [
                  Flexible(child: Text(rede.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  if (patrocinado) const SeloAnuncio(texto: 'Patrocinado'),
                ]),
                Text.rich(TextSpan(style: TextStyle(fontSize: 14, color: context.cores.onSurfaceVariant), children: [
                  if (distancia != null)
                    TextSpan(text: '${textoDistancia(distancia!)} · ', style: TextStyle(fontWeight: FontWeight.w800, color: context.cores.onSurface)),
                  TextSpan(text: 'encarte até ${diaMes(rede.ate)}'),
                ])),
                if (clube != null) ...[const SizedBox(height: 4), Etiqueta('Preço especial com $clube')],
              ]),
            ),
            Icon(Icons.chevron_right, color: context.cores.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}
