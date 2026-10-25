import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/cache.dart';
import '../../core/formato.dart';
import '../../core/modelos.dart';
import '../../core/paginador.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';
import '../avisos/avisos.dart';

final _db = Supabase.instance.client;

/// Tela 4 do protótipo: as ofertas válidas de um mercado, por categoria, com banner intercalado.
class MercadoPage extends StatefulWidget {
  const MercadoPage({super.key, required this.slug});
  final String slug;

  @override
  State<MercadoPage> createState() => _MercadoPageState();
}

class _MercadoPageState extends State<MercadoPage> {
  Rede? _rede;
  List<String> _secoes = [];
  String? _secao; // null = Tudo
  List<Anuncio> _banners = [];

  late final _ofertas = Paginador<Oferta>((de, ate) async {
    var q = _db.from('oferta_lista').select().eq('rede_slug', widget.slug);
    if (_secao != null) q = q.eq('secao', _secao!);
    Future<List<Map<String, dynamic>>> buscar() => q.order('secao', nullsFirst: false).order('id').range(de, ate);
    // primeira página de "Tudo" salva para abrir sem internet
    return (await (de == 0 && _secao == null ? comCache('mercado_${widget.slug}', buscar) : buscar())).map(Oferta.fromJson).toList();
  });

  @override
  void initState() {
    super.initState();
    _ofertas.proxima(_atualizar);
    _db.from('rede_com_ofertas').select().eq('slug', widget.slug).maybeSingle().then(
        (j) => mounted ? setState(() => _rede = j == null ? null : Rede.fromJson(j)) : null, onError: (_) {});
    _db.rpc('secoes_da_rede', params: {'slug': widget.slug}).then(
        (r) => mounted ? setState(() => _secoes = [for (final s in r as List) s['secao'] as String]) : null, onError: (_) {});
    anunciosDoFormato('banner').then((a) => mounted ? setState(() => _banners = a) : null, onError: (_) {});
  }

  /// A resposta pode chegar depois de a pessoa sair da tela: setState aí derrubava o app (Crashlytics 0.3.0).
  void _atualizar() {
    if (mounted) setState(() {});
  }

  void _filtrar(String? secao) {
    setState(() => _secao = secao);
    _ofertas.reiniciar();
    _ofertas.proxima(_atualizar);
  }

  @override
  Widget build(BuildContext context) {
    final r = _rede;
    final clube = Mercado.de(widget.slug).clube;
    final lista = intercalar(_ofertas.itens, _banners);
    final c = context.cores;
    return Scaffold(
      appBar: AppBar(
        leading: inicioSeAbriuPorLink(context),
        titleSpacing: 0,
        title: Row(spacing: 12, children: [
          AvatarMercado(widget.slug, tamanho: 40),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r?.nome ?? '', style: fredoka(20, cor: c.onSurface)),
              if (r != null)
                Text('Encarte vale até ${diaMes(r.ate)} · ${r.lojas} ${r.lojas == 1 ? 'loja' : 'lojas'} em GV',
                    style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
            ]),
          ),
        ]),
        actions: [BotaoAviso.mercado(slug: widget.slug, nome: r?.nome ?? 'mercado')],
      ),
      body: CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList.list(children: [
            if (_secoes.length > 1)
              // Row rolável em vez de altura fixa: com fonte grande os chips crescem sem cortar o texto
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(spacing: 8, children: [
                  for (final s in [null, ..._secoes])
                    FilterChip(label: Text(s ?? 'Tudo'), selected: _secao == s, onSelected: (_) => _filtrar(s)),
                ]),
              ),
            const SizedBox(height: 12),
            if (clube != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(16)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Icon(Icons.info_outline, size: 18, color: c.onPrimaryContainer),
                  Expanded(
                    child: Text('O selo mostra o preço para quem tem cadastro no $clube. Sem cadastro, vale o preço grande.',
                        style: TextStyle(fontSize: 13, height: 1.4, color: c.onPrimaryContainer)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: lista.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: switch (lista[i]) {
                Oferta o => CardOferta(o, mostrarMercado: false),
                EspacoAnuncio e => EspacoAnuncioView(anuncio: e.anuncio, alturaRede: 90),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _ofertas.erro
                ? Erro(onTentar: () => _ofertas.proxima(_atualizar))
                : _ofertas.fim && _ofertas.itens.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24), child: Text('Nenhuma oferta desta categoria no encarte atual.', textAlign: TextAlign.center))
                    : _ofertas.fim
                        ? const SizedBox.shrink()
                        : VerMais(carregando: _ofertas.carregando, onPressed: () => _ofertas.proxima(_atualizar)),
          ),
        ),
      ]),
    );
  }
}
