import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelos.dart';

final _db = Supabase.instance.client;

class ItemLista {
  ItemLista.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        texto = j['texto'] as String,
        quantidade = j['quantidade'] as int,
        pego = j['pego'] as bool,
        ofertaId = j['oferta_id'] as int?,
        redeId = j['rede_id'] as int?,
        redeNome = j['rede_nome'] as String?,
        redeSlug = j['rede_slug'] as String?,
        preco = (j['preco'] as num?)?.toDouble(),
        precoClube = (j['preco_clube'] as num?)?.toDouble(),
        validadeFim = j['validade_fim'] == null ? null : DateTime.parse(j['validade_fim'] as String);

  final int id, quantidade;
  final String texto;
  final bool pego;
  final int? ofertaId, redeId;
  final String? redeNome, redeSlug;
  final double? preco, precoClube;
  final DateTime? validadeFim;
}

/// Lista de compras sem login (migration 9): quem tem o código tem acesso.
/// [Lista.minha] é a do aparelho (código de dono salvo); [Lista.recebida] abre um link.
class Lista extends ChangeNotifier {
  Lista.recebida(this._codigo) : _salvar = false;
  Lista._minha() : _salvar = true;

  /// A lista deste aparelho; nasce no primeiro "Adicionar".
  static final minha = Lista._minha();

  static const _chave = 'lista_codigo_dono';
  final bool _salvar;
  String? _codigo;
  String? id, permissao, nomeDono;
  Map<String, dynamic>? codigos; // só o dono recebe: {marcar, ver}
  DateTime? atualizadaEm;
  List<ItemLista> itens = [];
  bool carregando = false, erro = false;

  /// Sem internet: mostrando a última versão salva no aparelho (marcar e editar ficam para depois).
  bool salva = false;
  RealtimeChannel? _canal;

  bool get podeEditar => !salva && (permissao == null || permissao == 'dono');
  bool get podeMarcar => !salva && (podeEditar || permissao == 'marcar');
  int get quantidadeTotal => itens.length;

  /// Mercados com itens na lista (para "5 itens em 3 mercados").
  int get mercados => itens.map((i) => i.redeId).whereType<int>().toSet().length;

  ItemLista? itemDaOferta(int ofertaId) => itens.where((i) => i.ofertaId == ofertaId).firstOrNull;

  /// Na abertura do app: recupera a lista deste aparelho, se existir.
  Future<void> iniciar() async {
    if (_salvar) _codigo = (await SharedPreferences.getInstance()).getString(_chave);
    if (_codigo != null) await carregar();
  }

  Future<void> carregar() async {
    if (_codigo == null) return;
    carregando = true;
    // Chamada no initState de uma tela: avisar já marcaria outros widgets da lista no meio do build
    // (Crashlytics, 0.1.0). O microtask roda depois do frame em construção.
    await Future<void>.value();
    notifyListeners();
    try {
      final j = await _db.rpc('lista_ler', params: {'codigo': _codigo}) as Map<String, dynamic>;
      _aplicar(j);
      erro = salva = false;
      _ouvir();
      await (await SharedPreferences.getInstance()).setString(_chaveSalva, jsonEncode({...j, '_codigo': _codigo}));
    } on PostgrestException catch (e) {
      erro = true;
      // Lista apagada no servidor: este aparelho começa outra no próximo "Adicionar".
      if (e.message.contains('não encontrada')) {
        await (await SharedPreferences.getInstance()).remove(_chaveSalva);
        if (_salvar) await _esquecer();
      }
    } catch (_) {
      // sem internet (sinal ruim no mercado): a última versão salva, se houver
      final s = (await SharedPreferences.getInstance()).getString(_chaveSalva);
      final salvo = s == null ? null : jsonDecode(s) as Map<String, dynamic>;
      if (salvo != null && salvo['_codigo'] == _codigo && id == null) {
        _aplicar(salvo);
        salva = true;
      } else {
        erro = true;
      }
    }
    carregando = false;
    notifyListeners();
  }

  // Uma vaga para a minha e uma para a última recebida: listas de outras pessoas não se acumulam no aparelho.
  String get _chaveSalva => _salvar ? 'lista_salva_minha' : 'lista_salva_recebida';

  void _aplicar(Map<String, dynamic> j) {
    id = j['id'] as String;
    permissao = j['permissao'] as String;
    nomeDono = j['nome_dono'] as String?;
    codigos = j['codigos'] as Map<String, dynamic>?;
    atualizadaEm = DateTime.parse(j['atualizado_em'] as String).toLocal();
    itens = (j['itens'] as List).map((i) => ItemLista.fromJson(i)).toList();
  }

  /// Tempo real: o banco avisa "mudou" no canal da lista; recarregamos.
  void _ouvir() {
    if (_canal != null || id == null) return;
    _canal = _db.channel('lista-$id')..onBroadcast(event: 'mudou', callback: (_) => _recarregarLogo())..subscribe();
  }

  // O canal é público (quem tem o link sabe o id): no máximo uma leitura por segundo, mesmo com rajada de avisos.
  Timer? _espera;
  void _recarregarLogo() {
    if (_espera?.isActive ?? false) return;
    _espera = Timer(const Duration(seconds: 1), carregar);
  }

  Future<void> _garantirLista() async {
    if (_codigo != null) return;
    final c = await _db.rpc('lista_criar') as Map<String, dynamic>;
    _codigo = c['dono'] as String;
    await (await SharedPreferences.getInstance()).setString(_chave, _codigo!);
  }

  Future<void> _esquecer() async {
    await (await SharedPreferences.getInstance()).remove(_chaveSalva);
    _codigo = id = permissao = null;
    itens = [];
    await _canal?.unsubscribe();
    _canal = null;
    await (await SharedPreferences.getInstance()).remove(_chave);
  }

  Future<void> _rpc(String funcao, Map<String, dynamic> params) async {
    await _db.rpc(funcao, params: {'codigo': _codigo, ...params});
    await carregar();
  }

  /// Oferta vai para o grupo do mercado dela; a mesma oferta de novo soma 1.
  Future<void> adicionar(Oferta o) async {
    await _garantirLista();
    final texto = o.nome.length > 120 ? o.nome.substring(0, 120) : o.nome; // limite do banco
    await _rpc('lista_adicionar', {'oferta_id': o.id, 'texto': texto, 'quantidade': 1});
  }

  /// Item anotado à mão ("Pão francês"), sem mercado definido.
  Future<void> anotar(String texto) async {
    if (texto.trim().isEmpty) return;
    await _garantirLista();
    await _rpc('lista_adicionar', {'oferta_id': null, 'texto': texto.trim(), 'quantidade': 1});
  }

  Future<void> mudarQuantidade(ItemLista i, int quantidade) =>
      _rpc('lista_quantidade', {'item_id': i.id, 'quantidade': quantidade});

  Future<void> marcar(ItemLista i, bool pego) => _rpc('lista_marcar', {'item_id': i.id, 'pego': pego});

  Future<void> nomear(String nome) => _rpc('lista_nomear', {'nome_dono': nome});

  /// Tira todos os itens (migration 18); a lista e os links compartilhados continuam valendo.
  Future<void> esvaziar() => _rpc('lista_esvaziar', {});

  /// Apaga a lista no servidor (migration 10): os links compartilhados param de abrir.
  Future<void> apagar() async {
    if (_codigo == null) return;
    await _db.rpc('lista_apagar', params: {'codigo': _codigo});
    await _esquecer();
    notifyListeners();
  }

  @override
  void dispose() {
    _espera?.cancel();
    _canal?.unsubscribe();
    super.dispose();
  }
}
