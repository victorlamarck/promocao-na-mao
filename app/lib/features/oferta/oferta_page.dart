import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/formato.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';
import '../avisos/avisos.dart';

final _db = Supabase.instance.client;

/// Tela 5 do protótipo: a oferta explicada em português simples, com "Adicionar à lista" fixo embaixo,
/// e a comparação com os outros mercados (comparar_oferta): o mesmo produto e, embaixo, os parecidos.
class OfertaPage extends StatefulWidget {
  const OfertaPage({super.key, required this.id, this.oferta});
  final int id;

  /// A oferta do card que foi tocado (extra da rota): aparece na hora, enquanto o banco confirma.
  final Oferta? oferta;

  @override
  State<OfertaPage> createState() => _OfertaPageState();
}

class _OfertaPageState extends State<OfertaPage> {
  late Oferta? _o = widget.oferta;
  var _venceu = false, _erro = false, _bannerPronto = false;
  List<String>? _lojas; // null = ainda chegando
  Anuncio? _banner;
  var _comparacao = const Comparacao.vazia();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// A resposta pode chegar depois de a pessoa voltar: setState aí derrubava o app.
  void _mudar(VoidCallback f) {
    if (mounted) setState(f);
  }

  /// Tudo em paralelo, cada parte aparece quando chega. Só a oferta derruba a tela; lojas, banner e
  /// comparação, se falharem, ficam de fora.
  void _carregar() {
    _db.from('oferta_lista').select().eq('id', widget.id).maybeSingle().then((j) {
      final o = j == null ? null : Oferta.fromJson(j);
      _mudar(() {
        _o = o;
        _venceu = o == null; // venceu ou não existe
      });
      if (o != null && widget.oferta == null) _carregarLojas(o);
    }, onError: (_) => _mudar(() => _erro = _o == null)); // sem internet: fica a do card, se tiver
    if (widget.oferta case final o?) _carregarLojas(o);
    anunciosDoFormato('banner').then((b) => _mudar(() {
          _banner = b.isEmpty ? null : b[widget.id % b.length];
          _bannerPronto = true;
        }), onError: (_) => _mudar(() => _bannerPronto = true));
    _db.rpc('comparar_oferta', params: {'oferta_id': widget.id}).then(
        (r) => _mudar(() => _comparacao = Comparacao.fromJson(r as Map<String, dynamic>)), onError: (_) {});
  }

  void _carregarLojas(Oferta o) => _db
      .from('loja')
      .select('id, nome')
      .eq('rede_id', o.redeId)
      .order('nome')
      .then((l) => _mudar(() => _lojas = _ondeVale(o, l)), onError: (_) {});

  /// Nomes das lojas onde a oferta vale, aplicando o "exceto"/"somente" do encarte.
  static List<String> _ondeVale(Oferta o, List<Map<String, dynamic>> lojas) => [
        for (final l in lojas)
          if (switch (o.restricaoTipo) {
            'somente' => o.restricaoLojas.contains(l['id']),
            'exceto' => !o.restricaoLojas.contains(l['id']),
            _ => true,
          })
            l['nome'] as String,
      ];

  @override
  Widget build(BuildContext context) {
    final o = _o;
    return Scaffold(
      appBar: AppBar(
        leading: inicioSeAbriuPorLink(context),
        title: const Text('Oferta'),
        centerTitle: true,
        actions: [
          if (o?.produtoCodigo case final codigo?) BotaoAviso.produto(codigo: codigo, nome: o!.nome),
          IconButton(
            tooltip: 'Copiar link da oferta',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: linkDoSite('/oferta/${widget.id}')));
              avisar(context, 'Link copiado. É só colar no WhatsApp.', verLista: false);
            },
          ),
        ],
      ),
      bottomNavigationBar: o == null
          ? null
          : SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: BotaoAdicionar(o, largo: true))),
      body: switch (o) {
        _ when _venceu => Center(
            child: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
              Text('Esta oferta já venceu.', style: fredoka(20)),
              FilledButton(onPressed: () => context.go('/'), child: const Text('Ver ofertas de hoje')),
            ]),
          ),
        null when _erro => Erro(onTentar: () {
            setState(() => _erro = false);
            _carregar();
          }),
        null => const Center(child: CircularProgressIndicator()),
        final o => _Detalhe(o, _lojas ?? const [], _bannerPronto ? EspacoAnuncioView(anuncio: _banner) : null, _comparacao),
      },
    );
  }
}

class _Detalhe extends StatelessWidget {
  const _Detalhe(this.o, this.lojas, this.banner, this.comparacao);
  final Oferta o;
  final List<String> lojas;
  final Widget? banner; // o banco ainda não disse qual: nada, para não pedir um do AdMob à toa
  final Comparacao comparacao;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final clube = Mercado.de(o.redeSlug).clube ?? 'clube';
    final porKg = porUnidade(o.precoReferencia, o.unidadeReferencia, preco: o.preco);
    final secundario = TextStyle(fontSize: 13, color: c.onSurfaceVariant);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(spacing: 8, children: [
        AvatarMercado(o.redeSlug, tamanho: 12),
        Expanded(child: Text('${o.redeNome} · ${valeAte(o.validadeFim).toLowerCase()}', style: secundario)),
      ]),
      const SizedBox(height: 8),
      Text(o.nome, style: fredoka(24)),
      const SizedBox(height: 6),
      Text('No encarte: “${o.textoOriginal}”', style: secundario),
      const SizedBox(height: 14),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              const Expanded(child: Text('Preço para todos')),
              Text(o.preco == null ? 'Preço no mercado' : reais(o.preco!), style: fredoka(o.preco == null ? 18 : 32, cor: context.corPreco)),
            ]),
            if (porKg != null) Align(alignment: Alignment.centerRight, child: Text(porKg, style: secundario)),
            if (o.precoDe != null)
              Text.rich(TextSpan(style: secundario, children: [
                const TextSpan(text: 'Antes '),
                TextSpan(text: reais(o.precoDe!), style: const TextStyle(decoration: TextDecoration.lineThrough)),
              ])),
            if (o.precoClube != null) ...[
              const Divider(height: 20),
              Row(children: [
                Expanded(child: Text('Com cadastro no $clube', style: const TextStyle(fontWeight: FontWeight.w700))),
                Etiqueta(reais(o.precoClube!)),
              ]),
            ],
            if (o.condicao != null) ...[
              const SizedBox(height: 8),
              Etiqueta(o.condicao!, cor: c.onTertiaryContainer, fundo: c.tertiaryContainer),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(spacing: 4, children: [
            _Linha(Icons.schedule, valeAte(o.validadeFim), faltam(o.validadeFim, DateTime.now())),
            const Divider(height: 20),
            _Linha(
                Icons.place_outlined,
                switch (lojas.length) { 0 => 'Vale nas lojas de GV', 1 => 'Vale na loja ${lojas.first}', _ => 'Vale em ${lojas.length} lojas de GV' },
                lojas.length > 1 ? lojas.join(' · ') : null),
          ]),
        ),
      ),
      _EmOutrosMercados(o, comparacao),
      const SizedBox(height: 8),
      TextButton(onPressed: () => context.push('/mercado/${o.redeSlug}'), child: Text('Ver o encarte completo do ${o.redeNome}')),
      const SizedBox(height: 12),
      ?banner,
    ]);
  }
}

/// Decisão do dev (22/10): primeiro o mesmo produto em outros encartes; embaixo os parecidos (outra marca ou
/// tamanho), pelo preço do kg/litro. "Mais barato" = sai mais em conta por kg/litro que esta oferta.
class _EmOutrosMercados extends StatefulWidget {
  const _EmOutrosMercados(this.o, this.comparacao);
  final Oferta o;
  final Comparacao comparacao;

  @override
  State<_EmOutrosMercados> createState() => _EmOutrosMercadosState();
}

class _EmOutrosMercadosState extends State<_EmOutrosMercados> {
  static const _visiveis = 5;
  var _todos = false;

  bool _maisBarato(Oferta x) {
    final esta = widget.o.porUnidadeValor;
    return esta != null && x.porUnidadeTipo == widget.o.porUnidadeTipo && (x.porUnidadeValor ?? esta) < esta;
  }

  @override
  Widget build(BuildContext context) {
    final Comparacao(:mesmo, :similares) = widget.comparacao;
    if (mesmo.isEmpty && similares.isEmpty) return const SizedBox.shrink();
    Widget titulo(String t, [String? sub]) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: fredoka(20)),
            if (sub != null) Text(sub, style: TextStyle(fontSize: 13, color: context.cores.onSurfaceVariant)),
          ]),
        );
    Widget card(Oferta x) => Padding(
        padding: const EdgeInsets.only(bottom: 10), child: CardOferta(x, mostrarPorUnidade: true, maisBarato: _maisBarato(x)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (mesmo.isNotEmpty) ...[titulo('O mesmo produto em outros encartes'), ...mesmo.map(card)],
      if (similares.isNotEmpty) ...[
        titulo('Parecidos', 'Outra marca ou tamanho. Compare pelo preço do kg ou do litro.'),
        ...(_todos ? similares : similares.take(_visiveis)).map(card),
        if (!_todos && similares.length > _visiveis)
          TextButton(
              onPressed: () => setState(() => _todos = true),
              child: Text('Ver mais ${similares.length - _visiveis} parecidos')),
      ],
    ]);
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.titulo, this.detalhe);
  final IconData icone;
  final String titulo;
  final String? detalhe;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
        Icon(icone, color: context.cores.primary),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 1, children: [
            Text(titulo, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (detalhe != null) Text(detalhe!, style: TextStyle(fontSize: 13, color: context.cores.onSurfaceVariant)),
          ]),
        ),
      ]);
}
