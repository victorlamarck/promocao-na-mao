import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/cache.dart';
import '../../core/formato.dart';
import '../../core/modelos.dart';
import '../../core/paginador.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';
import '../lista/lista.dart';
import '../mercado/mercados_page.dart';
import '../sugestao/fale_com_a_gente.dart';

final _db = Supabase.instance.client;

/// Tela 1 do protótipo: busca, Sua lista, anotar item, mercados perto, ofertas de hoje.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  // Rodízio entre os mercados, feito no banco (oferta_inicio, migration 21); `ordem` é única, então a paginação
  // não repete nem pula.
  // A primeira página fica salva para abrir sem internet (as vencidas mostram "Encarte venceu").
  final _ofertas = Paginador<Oferta>((de, ate) async {
    Future<List<Map<String, dynamic>>> q() => _db.from('oferta_inicio').select().order('ordem', ascending: true).range(de, ate);
    return (await (de == 0 ? comCache('inicio', q) : q())).map(Oferta.fromJson).toList();
  });
  final _anotar = TextEditingController();
  late var _mercados = mercadosOrdenados();
  List<Anuncio> _anuncios = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _anotar.dispose();
    super.dispose();
  }

  /// A resposta pode chegar depois de a pessoa trocar de aba: setState aí derrubava o app (Crashlytics 0.3.0).
  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> _carregar() async {
    _ofertas.reiniciar();
    setState(() { _mercados = mercadosOrdenados(); });
    await _ofertas.proxima(_atualizar);
    anunciosDoFormato('feed').then((a) => mounted ? setState(() => _anuncios = a) : null, onError: (_) {});
  }

  Future<void> _anotarItem() async {
    final texto = _anotar.text;
    if (texto.trim().isEmpty) return;
    _anotar.clear();
    try {
      await Lista.minha.anotar(texto);
      if (mounted) avisar(context, 'Anotado na lista');
    } catch (_) {
      if (mounted) avisar(context, 'Não deu para anotar agora. Tenta de novo?', verLista: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lista = intercalar(_ofertas.itens, _anuncios);
    final c = context.cores;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Promoção na Mão', style: fredoka(24, cor: c.primary)),
                  Text('Governador Valadares · ofertas que valem hoje', style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
                  FutureBuilder(
                    future: _mercados,
                    builder: (context, s) {
                      final datas = s.data?.$1.map((r) => r.atualizadoEm).whereType<DateTime>() ?? const <DateTime>[];
                      if (datas.isEmpty) return const SizedBox.shrink();
                      return Text(atualizado(datas.reduce((a, b) => a.isAfter(b) ? a : b), DateTime.now()),
                          style: TextStyle(fontSize: 12, color: c.onSurfaceVariant));
                    },
                  ),
                ]),
              ),
              IconButton(
                  tooltip: 'Sugestão ou problema no app', onPressed: () => faleComAGente(context), icon: const Icon(Icons.feedback_outlined)),
              IconButton(tooltip: 'Cor e tema do app', onPressed: () => _escolherCor(context), icon: const Icon(Icons.palette_outlined)),
            ]),
            const SizedBox(height: 12),
            SearchBar(
              hintText: 'Buscar: arroz, café, cerveja…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onTap: () => context.go('/buscar'),
              onSubmitted: (t) => context.go('/buscar?q=${Uri.encodeQueryComponent(t)}'),
            ),
            const SizedBox(height: 16),
            const _SuaLista(),
            const SizedBox(height: 12),
            TextField(
              controller: _anotar,
              maxLength: 120, // limite do banco (lista_item.texto)
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _anotarItem(),
              decoration: InputDecoration(
                labelText: 'Anotar item na lista',
                hintText: 'Ex.: pão francês',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                suffixIcon: IconButton(tooltip: 'Anotar', onPressed: _anotarItem, icon: const Icon(Icons.add)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text('Mercados perto de você', style: fredoka(20))),
              TextButton(onPressed: () => context.go('/mercados'), child: const Text('Ver todos')),
            ]),
            FutureBuilder(
              future: _mercados,
              builder: (context, s) {
                if (!s.hasData) return const SizedBox(height: 8);
                final (redes, distancias, destaque) = s.data!;
                return Column(children: [
                  for (final r in redes.take(3)) ...[
                    CardMercado(r, distancia: distancias[r.id], patrocinado: r.id == destaque),
                    const SizedBox(height: 8),
                  ],
                ]);
              },
            ),
            const SizedBox(height: 12),
            Text('Ofertas de hoje', style: fredoka(20)),
            const SizedBox(height: 10),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => switch (lista[i]) {
              Oferta o => CardOferta(o),
              EspacoAnuncio e => EspacoAnuncioView(anuncio: e.anuncio),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _ofertas.erro
                ? Erro(onTentar: () => _ofertas.proxima(_atualizar))
                : _ofertas.fim
                    ? Text('Mostramos só ofertas que valem hoje.', textAlign: TextAlign.center, style: TextStyle(color: c.onSurfaceVariant))
                    : VerMais(carregando: _ofertas.carregando, onPressed: () => _ofertas.proxima(_atualizar)),
          ),
        ),
      ]),
    );
  }
}

/// Card "Sua lista": quantos itens, em quantos mercados, Ver lista e Compartilhar.
class _SuaLista extends StatelessWidget {
  const _SuaLista();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Lista.minha,
        builder: (context, _) {
          final l = Lista.minha;
          final c = context.cores;
          final n = l.quantidadeTotal;
          final resumo = n == 0
              ? 'Sua lista tá vazia. Bora dar uma olhada nas ofertas de hoje?'
              : '$n ${n == 1 ? 'item' : 'itens'}${l.mercados > 0 ? ' em ${l.mercados} ${l.mercados == 1 ? 'mercado' : 'mercados'}' : ''}';
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text('Sua lista', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.onPrimary.withValues(alpha: 0.85))),
              Text(resumo, style: n == 0 ? TextStyle(fontSize: 15, color: c.onPrimary) : fredoka(24, cor: c.onPrimary)),
              if (n > 0) ...[
                const SizedBox(height: 8),
                Row(spacing: 8, children: [
                  FilledButton.tonal(onPressed: () => context.go('/lista'), child: const Text('Ver lista')),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: c.onPrimary, side: BorderSide(color: c.onPrimary)),
                    onPressed: () => context.go('/lista?compartilhar=1'),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Compartilhar'),
                  ),
                ]),
              ],
            ]),
          );
        },
      );
}

void _escolherCor(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 16, children: [
          Text('Aparência', style: fredoka(22)),
          const Text('Tema', style: TextStyle(fontWeight: FontWeight.w700)),
          ValueListenableBuilder(
            valueListenable: temaDoApp,
            builder: (context, atual, _) => SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                // sem ícone: "Automático" quebrava em duas linhas num celular de 412 dp
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Automático')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                ],
                selected: {atual},
                onSelectionChanged: (s) => escolherTemaDoApp(s.first),
              ),
            ),
          ),
          const Text('Cor', style: TextStyle(fontWeight: FontWeight.w700)),
          ValueListenableBuilder(
            valueListenable: corDoApp,
            builder: (context, atual, _) => Wrap(spacing: 12, children: [
              for (final (cor, nome) in coresDoApp)
                // O círculo mostra a cor que o app usa neste tema (no escuro o grafite sumia no fundo).
                if (temaApp(cor, Theme.of(context).brightness).colorScheme case final esquema)
                Semantics(
                  label: 'Usar $nome',
                  selected: atual == cor,
                  button: true,
                  child: InkResponse(
                    onTap: () => escolherCorDoApp(cor),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: esquema.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: atual == cor ? Theme.of(context).colorScheme.onSurface : Colors.transparent, width: 3),
                      ),
                      child: atual == cor ? Icon(Icons.check, color: esquema.onPrimary) : null,
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
