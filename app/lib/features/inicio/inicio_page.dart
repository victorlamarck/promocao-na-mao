import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/cache.dart';
import '../../core/formato.dart';
import '../../core/localizacao.dart';
import '../../core/modelos.dart';
import '../../core/paginador.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../avisos/avisos.dart';
import '../anuncios/anuncios.dart';
import '../anuncios/espaco_anuncio.dart';
import '../busca/busca_page.dart';
import '../lista/lista.dart';
import '../mercado/mercados_page.dart';
import '../sugestao/fale_com_a_gente.dart';

final _db = Supabase.instance.client;

/// Tela 1 do protótipo: busca, Sua lista, mercados perto, ofertas de hoje. Cada parte é um widget que se redesenha
/// sozinho: a página só guarda os mercados (cabeçalho e fileira) e o puxar para atualizar.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  late var _mercados = mercadosOrdenados();
  final _ofertas = GlobalKey<_OfertasDeHojeState>();

  Future<void> _recarregar() async {
    setState(() => _mercados = mercadosOrdenados());
    await _ofertas.currentState?.recarregar();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _recarregar,
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList.list(children: [
              _Cabecalho(_mercados),
              const SizedBox(height: 12),
              SearchBar(
                hintText: 'Buscar: arroz, café, cerveja…',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onTap: () {
                  context.go('/buscar');
                  // depois do quadro em que a aba Buscar aparece (escondida, ela não aceita foco)
                  WidgetsBinding.instance.addPostFrameCallback((_) => BuscaPage.foco.requestFocus());
                },
                onSubmitted: (t) => context.go('/buscar?q=${Uri.encodeQueryComponent(t)}'),
              ),
              const SizedBox(height: 12),
              const _SuaLista(),
              const SizedBox(height: 12),
              _FileiraMercados(_mercados),
              const SizedBox(height: 16),
            ]),
          ),
          _OfertasDeHoje(key: _ofertas),
        ]),
      );
}

typedef _Mercados = Future<(List<Rede>, Map<int, double>, int?)>;

/// Nome do app, "atualizado há…" (o encarte mais novo) e os botões de sugestão e de cor.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho(this.mercados);
  final _Mercados mercados;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Promoção na Mão', style: fredoka(24, cor: c.primary)),
          Text('Governador Valadares · ofertas que valem hoje', style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
          FutureBuilder(
            future: mercados,
            builder: (context, s) {
              final datas = s.data?.$1.map((r) => r.atualizadoEm).whereType<DateTime>() ?? const <DateTime>[];
              if (datas.isEmpty) return const SizedBox.shrink();
              return Text(atualizado(datas.reduce((a, b) => a.isAfter(b) ? a : b), DateTime.now()),
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant));
            },
          ),
        ]),
      ),
      if (avisosDisponiveis)
        IconButton(tooltip: 'Meus avisos', onPressed: () => context.push('/avisos'), icon: const Icon(Icons.notifications_none)),
      IconButton(tooltip: 'Sugestão ou problema no app', onPressed: () => faleComAGente(context), icon: const Icon(Icons.feedback_outlined)),
      IconButton(tooltip: 'Cor e tema do app', onPressed: () => _escolherCor(context), icon: const Icon(Icons.palette_outlined)),
    ]);
  }
}

/// Mercados perto, numa fileira que rola de lado, e "Ver todos".
class _FileiraMercados extends StatelessWidget {
  const _FileiraMercados(this.mercados);
  final _Mercados mercados;

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: mercados,
        builder: (context, s) {
          if (!s.hasData) return const SizedBox(height: 8);
          final (redes, distancias, destaque) = s.data!;
          // Row, não ListView de altura fixa: cresce com a fonte do sistema
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [
                for (final r in redes) _ChipMercado(r, distancia: distancias[r.id], patrocinado: r.id == destaque),
                ActionChip(label: const Text('Ver todos'), onPressed: () => context.go('/mercados')),
              ]),
            ),
          );
        },
      );
}

/// "Ofertas de hoje": título, filtro por categoria, a grade com anúncios e o "Ver mais". Paginar e filtrar
/// redesenham só esta parte.
class _OfertasDeHoje extends StatefulWidget {
  const _OfertasDeHoje({super.key});

  @override
  State<_OfertasDeHoje> createState() => _OfertasDeHojeState();
}

class _OfertasDeHojeState extends State<_OfertasDeHoje> {
  // Rodízio entre os mercados, feito no banco (oferta_inicio, migration 21); `ordem` é única, então a paginação
  // não repete nem pula. A primeira página fica salva para abrir sem internet (as vencidas mostram "Encarte venceu").
  // Filtro por categorias (coluna categoria, migration 23 do privado); vazio = todas. Só "todas" fica no cache.
  Set<String> _categorias = {};
  late final _ofertas = Paginador<Oferta>((de, ate) async {
    Future<List<Map<String, dynamic>>> q() {
      var f = _db.from('oferta_inicio').select();
      if (_categorias.isNotEmpty) f = f.inFilter('categoria', _categorias.toList());
      return f.order('ordem', ascending: true).range(de, ate);
    }
    return (await (de == 0 && _categorias.isEmpty ? comCache('inicio', q) : q())).map(Oferta.fromJson).toList();
  });
  List<Anuncio> _anuncios = [];

  @override
  void initState() {
    super.initState();
    recarregar();
  }

  /// A resposta pode chegar depois de a pessoa trocar de aba: setState aí derrubava o app (Crashlytics 0.3.0).
  void _atualizar() {
    if (mounted) setState(() {});
  }

  Future<void> recarregar() async {
    _ofertas.reiniciar();
    await _ofertas.proxima(_atualizar);
    anunciosDoFormato('feed').then((a) => mounted ? setState(() => _anuncios = a) : null, onError: (_) {});
  }

  Future<void> _filtrar(Set<String> categorias) async {
    setState(() => _categorias = categorias);
    _ofertas.reiniciar();
    await _ofertas.proxima(_atualizar);
  }

  @override
  Widget build(BuildContext context) {
    final linhas = emPares(intercalar(_ofertas.itens, _anuncios));
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverMainAxisGroup(slivers: [
        SliverList.list(children: [
          Text('Ofertas de hoje', style: fredoka(20)),
          const SizedBox(height: 8),
          FiltroCategoria(marcadas: _categorias, onMudar: _filtrar),
          const SizedBox(height: 10),
        ]),
        SliverList.separated(
          itemCount: linhas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => switch (linhas[i]) {
            List<Oferta> par => ParDeCards([for (final o in par) CardOferta(o)]),
            EspacoAnuncio e => EspacoAnuncioView(anuncio: e.anuncio),
            _ => const SizedBox.shrink(),
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          sliver: SliverToBoxAdapter(
            child: _ofertas.erro
                ? Erro(onTentar: () => _ofertas.proxima(_atualizar))
                : _ofertas.fim
                    ? Text(
                        _ofertas.itens.isEmpty && _categorias.isNotEmpty
                            ? 'Nenhuma oferta de ${_categorias.join(' ou ')} hoje.'
                            : 'Mostramos só ofertas que valem hoje.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.cores.onSurfaceVariant))
                    : VerMais(carregando: _ofertas.carregando, onPressed: () => _ofertas.proxima(_atualizar)),
          ),
        ),
      ]),
    );
  }
}

/// Faixa "Sua lista" de uma linha: quantos itens e em quantos mercados, Compartilhar e Anotar; tocar abre a lista.
/// Redesenha só quando o número de itens ou de mercados muda.
class _SuaLista extends StatelessWidget {
  const _SuaLista();

  Future<void> _anotar(BuildContext context) async {
    final texto = await showModalBottomSheet<String>(
        context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const _FolhaAnotar());
    if (texto == null || texto.trim().isEmpty || !context.mounted) return;
    try {
      await Lista.minha.anotar(texto);
      if (context.mounted) avisar(context, 'Anotado na lista');
    } catch (_) {
      if (context.mounted) avisar(context, 'Não deu para anotar agora. Tenta de novo?', verLista: false);
    }
  }

  @override
  Widget build(BuildContext context) => DaLista(
        ler: (l) => (l.quantidadeTotal, l.mercados),
        builder: (context, v) {
          final (n, mercados) = v;
          final c = context.cores;
          final resumo = n == 0
              ? 'Sua lista está vazia'
              : '$n ${n == 1 ? 'item' : 'itens'}${mercados > 0 ? ' em $mercados ${mercados == 1 ? 'mercado' : 'mercados'}' : ''}';
          return Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.go('/lista'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                child: Row(children: [
                  Icon(Icons.checklist, color: c.onPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(resumo, style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w700))),
                  if (n > 0)
                    IconButton(
                        tooltip: 'Compartilhar a lista',
                        onPressed: () => context.go('/lista?compartilhar=1'),
                        icon: Icon(Icons.share_outlined, color: c.onPrimary, size: 20)),
                  TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: c.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 10)),
                      onPressed: () => _anotar(context),
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('Anotar')),
                ]),
              ),
            ),
          );
        },
      );
}

/// Folha do "Anotar" (item à mão, sem mercado): devolve o texto ao fechar. Dona do próprio campo.
class _FolhaAnotar extends StatefulWidget {
  const _FolhaAnotar();

  @override
  State<_FolhaAnotar> createState() => _FolhaAnotarState();
}

class _FolhaAnotarState extends State<_FolhaAnotar> {
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: TextField(
          controller: _texto,
          autofocus: true,
          maxLength: 120, // limite do banco (lista_item.texto)
          textInputAction: TextInputAction.done,
          onSubmitted: (t) => Navigator.pop(context, t),
          decoration: InputDecoration(
            labelText: 'Anotar item na lista',
            hintText: 'Ex.: pão francês',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            suffixIcon: IconButton(tooltip: 'Anotar', onPressed: () => Navigator.pop(context, _texto.text), icon: const Icon(Icons.add)),
          ),
        ),
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

/// Mercado na fileira da Início, compacto: logo, nome e distância (o encarte e o clube ficam na aba Mercados).
class _ChipMercado extends StatelessWidget {
  const _ChipMercado(this.rede, {this.distancia, this.patrocinado = false});
  final Rede rede;
  final double? distancia;
  final bool patrocinado;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Material(
      color: c.surface,
      shape: StadiumBorder(side: BorderSide(color: c.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/mercado/${rede.slug}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          child: Row(spacing: 8, children: [
            AvatarMercado(rede.slug, tamanho: 28),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(rede.nome, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              if (patrocinado)
                Text('Patrocinado', style: TextStyle(fontSize: 11, color: c.onSurfaceVariant))
              else if (distancia != null)
                Text(textoDistancia(distancia!), style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
            ]),
          ]),
        ),
      ),
    );
  }
}
