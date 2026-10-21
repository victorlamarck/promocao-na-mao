import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelos.dart';
import '../../core/paginador.dart';
import '../../core/widgets.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';

final _db = Supabase.instance.client;

/// Tela 2 do protótipo: busca por texto (buscar_ofertas), filtro por mercado, patrocinado no topo.
class BuscaPage extends StatefulWidget {
  const BuscaPage({super.key, this.termoInicial = ''});
  final String termoInicial;

  @override
  State<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends State<BuscaPage> {
  late final _campo = TextEditingController(text: widget.termoInicial);
  Timer? _espera;
  String? _rede; // slug; null = todos
  bool _menorPreco = false;
  int? _total;
  List<Rede> _redes = [];
  List<Anuncio> _patrocinados = [];

  late final _resultados = Paginador<Oferta>((de, ate) async {
    var q = _db.rpc('buscar_ofertas', params: {'termo': _campo.text});
    if (_rede != null) q = q.eq('rede_slug', _rede!);
    final ordenada = _menorPreco ? q.order('preco', nullsFirst: false).order('id') : q;
    final r = await ordenada.range(de, ate).count(CountOption.exact);
    _total = r.count;
    return (r.data as List).map((j) => Oferta.fromJson(j)).toList();
  });

  @override
  void initState() {
    super.initState();
    _db.from('rede_com_ofertas').select().order('nome').then(
        (r) => setState(() => _redes = r.map(Rede.fromJson).toList()), onError: (_) {});
    if (_campo.text.isNotEmpty) _buscar();
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
    _resultados.proxima(() => setState(() {}));
    anunciosDaBusca(termo).then((a) {
      if (termo == _campo.text) setState(() => _patrocinados = a);
    }, onError: (_) {});
  }

  /// Espera a pessoa parar de digitar (0,4 s) antes de buscar.
  void _digitou(String _) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 400), _buscar);
  }

  @override
  Widget build(BuildContext context) {
    final buscou = _campo.text.trim().isNotEmpty;
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(spacing: 12, children: [
          TextField(
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
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final (slug, nome) in [(null, 'Todos'), ..._redes.map((r) => (r.slug, r.nome))])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(nome),
                    selected: _rede == slug,
                    onSelected: (_) {
                      setState(() => _rede = slug);
                      _buscar();
                    },
                  ),
                ),
            ]),
          ),
        ]),
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
                  Expanded(
                    child: Text(_total == null ? 'Buscando…' : '$_total ${_total == 1 ? 'oferta válida' : 'ofertas válidas'} hoje',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  DropdownButton<bool>(
                    value: _menorPreco,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: false, child: Text('Mais parecidas')),
                      DropdownMenuItem(value: true, child: Text('Menor preço')),
                    ],
                    onChanged: (v) {
                      setState(() => _menorPreco = v!);
                      _buscar();
                    },
                  ),
                ]),
                const SizedBox(height: 10),
                for (final a in _patrocinados) ...[EspacoAnuncioView(anuncio: a, selo: 'Patrocinado'), const SizedBox(height: 10)],
                for (final o in _resultados.itens) ...[CardOferta(o, mostrarPorUnidade: true), const SizedBox(height: 10)],
                if (_resultados.erro)
                  Erro(onTentar: () => _resultados.proxima(() => setState(() {})))
                else if (_resultados.fim && _resultados.itens.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhuma oferta encontrada hoje.\nTente outra palavra, como a marca ou o tipo do produto.',
                        textAlign: TextAlign.center, style: TextStyle(height: 1.4)),
                  )
                else if (!_resultados.fim)
                  VerMais(carregando: _resultados.carregando, onPressed: () => _resultados.proxima(() => setState(() {}))),
              ]),
      ),
    ]);
  }
}
