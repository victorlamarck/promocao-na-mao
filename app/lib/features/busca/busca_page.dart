import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelos.dart';
import '../../core/paginador.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';

final _db = Supabase.instance.client;

enum _Ordem {
  parecidas('Mais parecidas'),
  menorPreco('Menor preço'),
  porUnidade('Menor preço por kg/l');

  const _Ordem(this.rotulo);
  final String rotulo;
}

/// O que buscar: muda a cada busca nova (termo, filtros, categorias, ordem). [geracao] sobe a cada uma, e os
/// resultados recomeçam quando ela muda.
class _Consulta {
  const _Consulta({this.termo = '', this.mercados = const {}, this.semAtacado = false, this.ordem = _Ordem.parecidas,
      this.categorias = const {}, this.geracao = 0});
  final String termo;
  final Set<String> mercados; // slugs; vazio = todos
  final bool semAtacado;
  final _Ordem ordem;
  final Set<String> categorias; // coluna categoria (migration 23 do privado); vazio = todas
  final int geracao;

  bool get vazia => termo.trim().isEmpty && categorias.isEmpty;
  int get filtrosLigados => (mercados.isEmpty ? 0 : 1) + (semAtacado ? 1 : 0);

  _Consulta nova({String? termo, Set<String>? mercados, bool? semAtacado, _Ordem? ordem, Set<String>? categorias}) => _Consulta(
      termo: termo ?? this.termo,
      mercados: mercados ?? this.mercados,
      semAtacado: semAtacado ?? this.semAtacado,
      ordem: ordem ?? this.ordem,
      categorias: categorias ?? this.categorias,
      geracao: geracao + 1);
}

/// Tela 2 do protótipo: busca por texto (buscar_ofertas), filtros (mercados, sem atacado), patrocinado no topo.
/// A página guarda só a barra, o filtro por categoria e a [_Consulta]; os resultados paginam sozinhos.
class BuscaPage extends StatefulWidget {
  const BuscaPage({super.key, this.termoInicial = ''});
  final String termoInicial;

  /// A aba guarda a tela, então o autofocus só vale na primeira vez; a busca da Início foca por aqui.
  static final foco = FocusNode();

  @override
  State<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends State<BuscaPage> {
  late final _campo = TextEditingController(text: widget.termoInicial);
  Timer? _espera;
  late var _consulta = _Consulta(termo: widget.termoInicial);

  /// Termo novo vindo da Início (/buscar?q=) com a aba já aberta.
  @override
  void didUpdateWidget(BuscaPage antes) {
    super.didUpdateWidget(antes);
    if (widget.termoInicial.isEmpty || widget.termoInicial == antes.termoInicial) return;
    _campo.text = widget.termoInicial;
    _buscar();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _campo.dispose();
    super.dispose();
  }

  void _buscar({Set<String>? mercados, bool? semAtacado, _Ordem? ordem, Set<String>? categorias}) {
    _espera?.cancel();
    setState(() => _consulta =
        _consulta.nova(termo: _campo.text, mercados: mercados, semAtacado: semAtacado, ordem: ordem, categorias: categorias));
  }

  /// Espera a pessoa parar de digitar (0,4 s) antes de buscar.
  void _digitou(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), _buscar);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: TextField(
            controller: _campo,
            focusNode: BuscaPage.foco,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _digitou,
            onSubmitted: (_) => _buscar(),
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar: arroz, café, cerveja…',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
        // categorias logo abaixo da barra: dá para buscar escolhendo uma (ou mais) em vez de digitar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: FiltroCategoria(marcadas: _consulta.categorias, onMudar: (cats) => _buscar(categorias: cats)),
        ),
        Expanded(
          child: _consulta.vazia
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Digite o produto ou escolha uma categoria.\nMostramos só ofertas que valem hoje.',
                      textAlign: TextAlign.center, style: TextStyle(height: 1.4)),
                ))
              : _Resultados(
                  _consulta,
                  onFiltros: (mercados, semAtacado) => _buscar(mercados: mercados, semAtacado: semAtacado),
                  onOrdem: (o) => _buscar(ordem: o),
                ),
        ),
      ]);
}

/// Resultados da [_Consulta]: Filtros e ordem, total, patrocinados, a grade e o "Ver mais". Recomeça quando a
/// consulta muda; paginar redesenha só aqui.
class _Resultados extends StatefulWidget {
  const _Resultados(this.consulta, {required this.onFiltros, required this.onOrdem});
  final _Consulta consulta;
  final void Function(Set<String> mercados, bool semAtacado) onFiltros;
  final ValueChanged<_Ordem> onOrdem;

  @override
  State<_Resultados> createState() => _ResultadosState();
}

class _ResultadosState extends State<_Resultados> {
  int? _total;
  List<Rede> _redes = [];
  List<Anuncio> _patrocinados = [];

  late final _resultados = Paginador<Oferta>((de, ate) async {
    final k = widget.consulta;
    // Sem texto (só categoria): as ofertas de hoje na ordem da Início (oferta_inicio); com texto, a busca.
    final semTermo = k.termo.trim().isEmpty;
    PostgrestFilterBuilder<dynamic> q =
        semTermo ? _db.from('oferta_inicio').select() : _db.rpc('buscar_ofertas', params: {'termo': k.termo});
    if (k.mercados.isNotEmpty) q = q.inFilter('rede_slug', k.mercados.toList());
    if (k.categorias.isNotEmpty) q = q.inFilter('categoria', k.categorias.toList());
    // o mesmo critério de Oferta.atacado: a condição começa com "preço de atacado"
    if (k.semAtacado) q = q.or('condicao.is.null,condicao.not.like."preço de atacado*"');
    // order() do postgrest-dart é decrescente por padrão: ascending explícito
    final ordenada = switch (k.ordem) {
      _Ordem.parecidas => semTermo ? q.order('ordem', ascending: true) : q,
      _Ordem.menorPreco => q.order('preco', ascending: true).order('id', ascending: true),
      _Ordem.porUnidade => q.order('preco_referencia', ascending: true).order('id', ascending: true),
    };
    final r = await ordenada.range(de, ate).count(CountOption.exact);
    _total = r.count;
    return (r.data as List).map((j) => Oferta.fromJson(j)).toList();
  });

  @override
  void initState() {
    super.initState();
    _db.from('rede_com_ofertas').select().order('nome', ascending: true).then(
        (r) => mounted ? setState(() => _redes = r.map(Rede.fromJson).toList()) : null, onError: (_) {});
    _buscar();
  }

  @override
  void didUpdateWidget(_Resultados antes) {
    super.didUpdateWidget(antes);
    if (widget.consulta.geracao != antes.consulta.geracao) _buscar();
  }

  /// A resposta pode chegar depois de a pessoa sair da tela: setState aí derrubava o app (Crashlytics 0.3.0).
  void _atualizar() {
    if (mounted) setState(() {});
  }

  void _buscar() {
    _resultados.reiniciar();
    _total = null;
    _patrocinados = [];
    _resultados.proxima(_atualizar);
    final k = widget.consulta;
    if (k.termo.trim().isEmpty) return;
    anunciosDaBusca(k.termo).then((a) {
      if (mounted && k.geracao == widget.consulta.geracao) setState(() => _patrocinados = a);
    }, onError: (_) {});
  }

  /// Folha "Filtros": mercados (vários) e esconder atacado. Só vale ao tocar em "Ver ofertas".
  Future<void> _abrirFiltros() async {
    var mercados = {...widget.consulta.mercados};
    var semAtacado = widget.consulta.semAtacado;
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, mudar) => SafeArea(
          child: SingleChildScrollView( // muitos mercados ou fonte grande: rola em vez de estourar
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
              const Text('Filtros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Mercados', style: TextStyle(fontWeight: FontWeight.w700)),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilterChip(label: const Text('Todos'), selected: mercados.isEmpty, onSelected: (_) => mudar(() => mercados = {})),
                for (final r in _redes)
                  FilterChip(
                    label: Text(r.nome),
                    selected: mercados.contains(r.slug),
                    onSelected: (sim) => mudar(() => sim ? mercados.add(r.slug) : mercados.remove(r.slug)),
                  ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Esconder preço de atacado', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Ofertas que só valem comprando em quantidade'),
                value: semAtacado,
                onChanged: (v) => mudar(() => semAtacado = v),
              ),
              Row(spacing: 12, children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => mudar(() {
                      mercados = {};
                      semAtacado = false;
                    }),
                    child: const Text('Limpar'),
                  ),
                ),
                Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ver ofertas'))),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (aplicar == true && mounted) widget.onFiltros(mercados, semAtacado);
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.consulta;
    final baratas = maisBaratas(_resultados.itens); // entre as já carregadas
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        sliver: SliverList.list(children: [
          Row(children: [
            Badge(
              isLabelVisible: k.filtrosLigados > 0,
              label: Text('${k.filtrosLigados}'),
              child: OutlinedButton.icon(onPressed: _abrirFiltros, icon: const Icon(Icons.tune, size: 18), label: const Text('Filtros')),
            ),
            const Spacer(),
            DropdownButton<_Ordem>(
              value: k.ordem,
              underline: const SizedBox.shrink(),
              items: [for (final o in _Ordem.values) DropdownMenuItem(value: o, child: Text(o.rotulo))],
              onChanged: (v) => widget.onOrdem(v!),
            ),
          ]),
          Text(_total == null ? 'Buscando…' : '$_total ${_total == 1 ? 'oferta válida' : 'ofertas válidas'} hoje',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final a in _patrocinados) ...[EspacoAnuncioView(anuncio: a, selo: 'Patrocinado'), const SizedBox(height: 10)],
        ]),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: (_resultados.itens.length + 1) ~/ 2,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ParDeCards([
              for (final o in _resultados.itens.skip(i * 2).take(2))
                CardOferta(o, mostrarPorUnidade: true, maisBarato: baratas.contains(o.id)),
            ]),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverToBoxAdapter(
          child: _resultados.erro
              ? Erro(onTentar: () => _resultados.proxima(_atualizar))
              : _resultados.fim && _resultados.itens.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          k.filtrosLigados > 0
                              ? 'Nenhuma oferta encontrada hoje com esses filtros.\nTente tirar algum filtro ou buscar outra palavra.'
                              : 'Nenhuma oferta encontrada hoje.\nTente outra palavra, como a marca ou o tipo do produto.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.4)),
                    )
                  : _resultados.fim
                      ? const SizedBox.shrink()
                      : VerMais(carregando: _resultados.carregando, onPressed: () => _resultados.proxima(_atualizar)),
        ),
      ),
    ]);
  }
}
