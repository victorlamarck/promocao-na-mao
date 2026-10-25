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

/// Tela 2 do protótipo: busca por texto (buscar_ofertas), filtros (mercados, sem atacado), patrocinado no topo.
class BuscaPage extends StatefulWidget {
  const BuscaPage({super.key, this.termoInicial = ''});
  final String termoInicial;

  @override
  State<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends State<BuscaPage> {
  late final _campo = TextEditingController(text: widget.termoInicial);
  Timer? _espera;
  Set<String> _mercados = {}; // slugs; vazio = todos
  bool _semAtacado = false;
  _Ordem _ordem = _Ordem.parecidas;
  int? _total;
  List<Rede> _redes = [];
  List<Anuncio> _patrocinados = [];

  int get _filtrosLigados => (_mercados.isEmpty ? 0 : 1) + (_semAtacado ? 1 : 0);

  late final _resultados = Paginador<Oferta>((de, ate) async {
    var q = _db.rpc('buscar_ofertas', params: {'termo': _campo.text});
    if (_mercados.isNotEmpty) q = q.inFilter('rede_slug', _mercados.toList());
    // o mesmo critério de Oferta.atacado: a condição começa com "preço de atacado"
    if (_semAtacado) q = q.or('condicao.is.null,condicao.not.like."preço de atacado*"');
    // order() do postgrest-dart é decrescente por padrão: ascending explícito
    final ordenada = switch (_ordem) {
      _Ordem.parecidas => q,
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
    if (_campo.text.isNotEmpty) _buscar();
  }

  /// A resposta pode chegar depois de a pessoa sair da tela: setState aí derrubava o app (Crashlytics 0.3.0).
  void _atualizar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _espera?.cancel();
    _campo.dispose();
    super.dispose();
  }

  void _buscar() {
    _resultados.reiniciar();
    _total = null;
    final termo = _campo.text;
    if (termo.trim().isEmpty) return setState(() => _patrocinados = []);
    _resultados.proxima(_atualizar);
    anunciosDaBusca(termo).then((a) {
      if (mounted && termo == _campo.text) setState(() => _patrocinados = a);
    }, onError: (_) {});
  }

  /// Folha "Filtros": mercados (vários) e esconder atacado. Só vale ao tocar em "Ver ofertas".
  Future<void> _abrirFiltros() async {
    var mercados = {..._mercados};
    var semAtacado = _semAtacado;
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, mudar) => SafeArea(
          child: Padding(
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
    if (aplicar != true || !mounted) return;
    setState(() {
      _mercados = mercados;
      _semAtacado = semAtacado;
    });
    _buscar();
  }

  /// Espera a pessoa parar de digitar (0,4 s) antes de buscar.
  void _digitou(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), _buscar);
  }

  @override
  Widget build(BuildContext context) {
    final buscou = _campo.text.trim().isNotEmpty;
    final baratas = maisBaratas(_resultados.itens); // entre as já carregadas
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: TextField(
          controller: _campo,
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
      Expanded(
        child: !buscou
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Digite o produto que você procura.\nMostramos só ofertas que valem hoje.',
                    textAlign: TextAlign.center, style: TextStyle(height: 1.4)),
              ))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 24), children: [
                Row(children: [
                  Badge(
                    isLabelVisible: _filtrosLigados > 0,
                    label: Text('$_filtrosLigados'),
                    child: OutlinedButton.icon(onPressed: _abrirFiltros, icon: const Icon(Icons.tune, size: 18), label: const Text('Filtros')),
                  ),
                  const Spacer(),
                  DropdownButton<_Ordem>(
                    value: _ordem,
                    underline: const SizedBox.shrink(),
                    items: [for (final o in _Ordem.values) DropdownMenuItem(value: o, child: Text(o.rotulo))],
                    onChanged: (v) {
                      setState(() => _ordem = v!);
                      _buscar();
                    },
                  ),
                ]),
                Text(_total == null ? 'Buscando…' : '$_total ${_total == 1 ? 'oferta válida' : 'ofertas válidas'} hoje',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (final a in _patrocinados) ...[EspacoAnuncioView(anuncio: a, selo: 'Patrocinado'), const SizedBox(height: 10)],
                for (final o in _resultados.itens)
                  ...[CardOferta(o, mostrarPorUnidade: true, maisBarato: baratas.contains(o.id)), const SizedBox(height: 10)],
                if (_resultados.erro)
                  Erro(onTentar: () => _resultados.proxima(_atualizar))
                else if (_resultados.fim && _resultados.itens.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        _filtrosLigados > 0
                            ? 'Nenhuma oferta encontrada hoje com esses filtros.\nTente tirar algum filtro ou buscar outra palavra.'
                            : 'Nenhuma oferta encontrada hoje.\nTente outra palavra, como a marca ou o tipo do produto.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.4)),
                  )
                else if (!_resultados.fim)
                  VerMais(carregando: _resultados.carregando, onPressed: () => _resultados.proxima(_atualizar)),
              ]),
      ),
    ]);
  }
}
