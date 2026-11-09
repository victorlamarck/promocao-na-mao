import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/lista/lista.dart';
import 'formato.dart';
import 'modelos.dart';
import 'tema.dart';

/// Logo do mercado num círculo; sem logo, a sigla na cor do mercado. Pequena (< 20), só a bolinha de cor.
class AvatarMercado extends StatelessWidget {
  const AvatarMercado(this.slug, {super.key, this.tamanho = 48});
  final String? slug;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final m = Mercado.de(slug);
    if (m.logo != null && tamanho >= 20) {
      // borda fina: os logos de fundo branco não somem sobre o card claro
      return Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.cores.outlineVariant)),
        child: ClipOval(child: Image.asset(m.logo!, fit: BoxFit.cover, excludeFromSemantics: true)),
      );
    }
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: m.cor, shape: BoxShape.circle),
      child: tamanho < 20
          ? null
          : Text(m.sigla, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: tamanho / 3)),
    );
  }
}

/// Etiqueta pequena: preço de clube, condição ("Leve 12, pague 10"), selo.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.cor, this.fundo, this.linhas});
  final String texto;
  final Color? cor, fundo;
  final int? linhas; // null = o texto todo

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: fundo ?? context.cores.primaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Text(texto,
            maxLines: linhas,
            overflow: linhas == null ? null : TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: cor ?? context.cores.onPrimaryContainer)),
      );
}

/// Botão da AppBar quando a tela abriu direto por um link (sem tela para voltar): leva ao Início.
Widget? inicioSeAbriuPorLink(BuildContext context) => context.canPop()
    ? null
    : IconButton(tooltip: 'Início', onPressed: () => context.go('/'), icon: const Icon(Icons.home_outlined));

/// Aviso no rodapé com atalho para a lista ("Café adicionado no Atacadão · Ver lista").
void avisar(BuildContext context, String texto, {bool verLista = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      persist: false, // com ação, o Flutter deixa o aviso na tela até tocar; aqui ele cobria o "Apagar minha lista"
      action: verLista ? SnackBarAction(label: 'Ver lista', onPressed: () => context.go('/lista')) : null,
    ));
}

/// Ação na lista que pode falhar sem sinal (marcar, mudar quantidade): avisa em vez de falhar calada.
Future<bool> tentarNaLista(BuildContext context, Future<void> Function() acao) async {
  try {
    await acao();
    return true;
  } catch (_) {
    if (context.mounted) avisar(context, 'Não deu agora. Confira a internet e tente de novo.', verLista: false);
    return false;
  }
}

/// Redesenha só quando o pedaço da lista que interessa a este widget muda ([ler] devolve um valor comparável com ==,
/// ex. um record). A lista avisa a cada carga (e duas vezes por mudança): com ListenableBuilder, cada card da tela
/// se redesenhava a cada "+" em qualquer outro.
class DaLista<T> extends StatefulWidget {
  const DaLista({super.key, required this.ler, required this.builder, this.lista});
  final T Function(Lista lista) ler;
  final Widget Function(BuildContext context, T valor) builder;

  /// Padrão: [Lista.minha].
  final Lista? lista;

  @override
  State<DaLista<T>> createState() => _DaListaState<T>();
}

class _DaListaState<T> extends State<DaLista<T>> {
  Lista get _lista => widget.lista ?? Lista.minha;
  late T _valor = widget.ler(_lista);

  @override
  void initState() {
    super.initState();
    _lista.addListener(_mudou);
  }

  @override
  void didUpdateWidget(DaLista<T> antes) {
    super.didUpdateWidget(antes);
    final lista = antes.lista ?? Lista.minha;
    if (lista != _lista) {
      lista.removeListener(_mudou);
      _lista.addListener(_mudou);
    }
    _valor = widget.ler(_lista);
  }

  void _mudou() {
    final v = widget.ler(_lista);
    if (v != _valor) setState(() => _valor = v);
  }

  @override
  void dispose() {
    _lista.removeListener(_mudou);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _valor);
}

/// "− 2 +" (rótulos para leitor de tela: "Mais um café"). Vai até 999, o limite do banco.
class Contador extends StatelessWidget {
  const Contador({super.key, required this.quantidade, required this.nome, required this.onMudar, this.altura = 48, this.largo = false});
  final int quantidade;
  final String nome;
  final ValueChanged<int> onMudar;
  final double altura;

  /// Ocupa a largura toda (no lugar do "Adicionar"): "−" num canto, a quantidade no meio, "+" no outro.
  final bool largo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      height: altura,
      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(altura / 2)),
      child: Row(mainAxisSize: largo ? MainAxisSize.max : MainAxisSize.min, children: [
        IconButton(
          constraints: BoxConstraints.tight(Size.square(altura)), // no card estreito, o padrão de 48 estourava
          tooltip: quantidade == 1 ? 'Tirar $nome da lista' : 'Menos um $nome',
          onPressed: () => onMudar(quantidade - 1),
          icon: Icon(quantidade == 1 ? Icons.delete_outline : Icons.remove, color: c.onPrimary, size: 20),
        ),
        if (largo) const Spacer(),
        Text('$quantidade',
            style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
        if (largo) const Spacer(),
        IconButton(
          constraints: BoxConstraints.tight(Size.square(altura)),
          tooltip: 'Mais um $nome',
          onPressed: quantidade >= 999 ? null : () => onMudar(quantidade + 1),
          icon: Icon(Icons.add, color: c.onPrimary, size: 20),
        ),
      ]),
    );
  }
}

/// "Adicionar" da largura toda, que vira o contador quando a oferta já está na lista. Só ele se redesenha quando
/// a quantidade desta oferta muda ([DaLista]). [altura] 44 no card; 52 fixo embaixo na tela da oferta, onde,
/// já na lista, vira "Na sua lista" com a conta e o contador compacto.
class BotaoAdicionar extends StatelessWidget {
  const BotaoAdicionar(this.oferta, {super.key, this.altura = 44});
  final Oferta oferta;
  final double altura;

  @override
  Widget build(BuildContext context) => DaLista(
        ler: (l) => l.itemDaOferta(oferta.id)?.quantidade,
        builder: (context, quantidade) {
          if (quantidade != null) {
            final grande = altura > 48;
            final contador = Contador(
              quantidade: quantidade,
              nome: oferta.nome,
              altura: grande ? 48 : altura,
              largo: !grande,
              onMudar: (q) async {
                final item = Lista.minha.itemDaOferta(oferta.id);
                if (item == null) return;
                if (await tentarNaLista(context, () => Lista.minha.mudarQuantidade(item, q)) && q == 0 && context.mounted) {
                  avisar(context, 'Tirado da lista', verLista: false);
                }
              },
            );
            if (!grande) return contador;
            // tela da oferta: "Na sua lista" e a conta à esquerda, o contador compacto à direita
            final c = context.cores;
            final preco = oferta.preco;
            return Container(
              height: altura,
              padding: const EdgeInsets.only(left: 16, right: 2),
              decoration: BoxDecoration(
                  color: c.surfaceContainerHigh, borderRadius: BorderRadius.circular(altura / 2), border: Border.all(color: c.outlineVariant)),
              child: Row(spacing: 12, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Na sua lista', style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
                    Text(
                        preco == null
                            ? '$quantidade ${quantidade == 1 ? 'unidade' : 'unidades'}'
                            : quantidade == 1
                                ? reais(preco)
                                : '$quantidade × ${reais(preco)} = ${reais(preco * quantidade)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.corPreco)),
                  ]),
                ),
                contador,
              ]),
            );
          }
          return FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: Size(double.infinity, altura), padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: () async {
              try {
                await Lista.minha.adicionar(oferta);
                if (context.mounted) avisar(context, 'Adicionado no ${oferta.redeNome}');
              } catch (_) {
                if (context.mounted) avisar(context, 'Não deu para adicionar agora. Tenta de novo?', verLista: false);
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(altura > 48 ? 'Adicionar à lista' : 'Adicionar'),
          );
        },
      );
}

/// [avisoValidade] como selo: amarelo perto de vencer, vermelho vencido.
class SeloValidade extends StatelessWidget {
  const SeloValidade(this.fim, {super.key});
  final DateTime? fim;

  @override
  Widget build(BuildContext context) {
    final aviso = fim == null ? null : avisoValidade(fim!, DateTime.now());
    if (aviso == null) return const SizedBox.shrink();
    final venceu = aviso == 'Encarte venceu';
    const claro = Color(0xFFFFF3C4), escuro = Color(0xFF5C4300);
    final noEscuro = Theme.of(context).brightness == Brightness.dark; // no escuro, o mesmo par invertido
    return Etiqueta(aviso,
        cor: venceu ? context.cores.onErrorContainer : (noEscuro ? claro : escuro),
        fundo: venceu ? context.cores.errorContainer : (noEscuro ? escuro : claro));
  }
}

/// Categorias principais do catálogo (catalogo/categorias.json do privado), na ordem do filtro da Início.
const categoriasPrincipais = ['Mercearia', 'Açougue', 'Hortifruti', 'Frios e Laticínios', 'Padaria', 'Congelados', 'Bebidas',
    'Limpeza', 'Higiene', 'Pet', 'Casa'];

/// Ícone da categoria principal do catálogo, para a oferta sem foto e o filtro da Início.
// Emoji, como no site (formato.ts): colorido e reconhecível de longe; o mesmo do filtro e do "Sem foto".
String iconeDaCategoria(String? categoria) => switch (categoria) {
      'Mercearia' => '🛒',
      'Frios e Laticínios' => '🧀',
      'Açougue' => '🥩',
      'Congelados' => '🧊',
      'Hortifruti' => '🥬',
      'Padaria' => '🥖',
      'Bebidas' => '🥤',
      'Limpeza' => '🧽',
      'Higiene' => '🧴',
      'Pet' => '🐾',
      'Casa' => '🏠',
      _ => '🛍️',
    };

/// Foto do produto (recorte do encarte) num quadro branco da largura do card. Sem foto (ou se não carregar), o
/// ícone da categoria com "Sem foto", para ninguém achar que é a foto do produto. Decorativa: o nome está no card.
class FotoOferta extends StatelessWidget {
  const FotoOferta(this.oferta, {super.key, required this.altura});
  final Oferta oferta;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final semFoto = ExcludeSemantics(
      child: ColoredBox(
        color: c.surfaceContainerHighest,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 4, children: [
          Text(iconeDaCategoria(oferta.categoria), style: TextStyle(fontSize: altura * 0.3)),
          Text('Sem foto', style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
        ]),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: oferta.fotoUrl == null
            ? semFoto
            : ColoredBox(
                color: Colors.white,
                child: Image.network(oferta.fotoUrl!,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    cacheHeight: (altura * MediaQuery.devicePixelRatioOf(context)).round(),
                    errorBuilder: (_, _, _) => semFoto),
              ),
      ),
    );
  }
}

/// Ofertas em 2 colunas: junta ofertas seguidas em pares (`List<Oferta>`); outro item (anúncio) ocupa a linha toda.
List<Object> emPares(Iterable<Object> itens) {
  final linhas = <Object>[];
  for (final x in itens) {
    final ultima = linhas.lastOrNull;
    if (x is Oferta && ultima is List<Oferta> && ultima.length == 1) {
      ultima.add(x);
    } else {
      linhas.add(x is Oferta ? <Oferta>[x] : x);
    }
  }
  return linhas;
}

/// Uma linha da grade de ofertas: 2 cards da mesma altura (o da direita vazio se a lista for ímpar).
// shortcut: 2 colunas em qualquer largura; em tablet/web largo, calcular as colunas pela largura.
class ParDeCards extends StatelessWidget {
  const ParDeCards(this.cards, {super.key});
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
          Expanded(child: cards[0]),
          Expanded(child: cards.length > 1 ? cards[1] : const SizedBox.shrink()),
        ]),
      );
}

/// Card de uma oferta: mercado e validade, nome, preço (o elemento mais forte), clube, "antes", condição, Adicionar.
class CardOferta extends StatelessWidget {
  const CardOferta(this.oferta, {super.key, this.mostrarPorUnidade = false, this.mostrarMercado = true, this.maisBarato = false});
  final Oferta oferta;
  final bool mostrarPorUnidade, mostrarMercado;

  /// Selo "Mais barato por kg/litro" (busca e comparação).
  final bool maisBarato;

  @override
  Widget build(BuildContext context) {
    final o = oferta;
    final c = context.cores;
    final clube = Mercado.de(o.redeSlug).clube ?? 'clube';
    // preço do clube mais baixo: ele vira o preço grande e a etiqueta mostra o preço sem o clube
    final clubeMenor = o.precoClube != null && (o.preco == null || o.precoClube! < o.preco!);
    final valor = clubeMenor ? o.precoClube : o.preco;
    // o R$/kg do banco já é o do preço mais baixo (o mesmo do preço grande)
    final unidade = mostrarPorUnidade ? porUnidade(o.porUnidadeValor, o.porUnidadeTipo, preco: valor) : null;
    final preco = valor == null ? 'preço no mercado' : reais(valor);
    final etiquetaClube = o.precoClube == null
        ? null
        : clubeMenor
            ? 'com $clube${o.preco == null ? '' : ' · ${reais(o.preco!)} sem'}'
            : '${reais(o.precoClube!)} com $clube';
    final aviso = avisoValidade(o.validadeFim, DateTime.now());
    // Leitor de tela: o card vira uma frase só ("Café 500 g, R$ 12,90 no Atacadão, antes R$ 15,90"); o Adicionar fica à parte.
    final rotulo = [
      o.nome,
      mostrarMercado ? '$preco no ${o.redeNome}' : preco,
      ?unidade,
      ?etiquetaClube,
      if (o.precoDe != null) 'antes ${reais(o.precoDe!)}',
      ?o.condicaoCurta,
      if (o.atacado) 'preço de atacado',
      if (maisBarato) 'o mais barato',
      ?aviso,
    ].join(', ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/oferta/${o.id}', extra: o),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
            // foto com o logo do mercado no canto
            Stack(children: [
              FotoOferta(o, altura: 120),
              if (mostrarMercado) Positioned(top: 6, left: 6, child: ExcludeSemantics(child: AvatarMercado(o.redeSlug, tamanho: 26))),
            ]),
            Semantics(
              label: rotulo,
              excludeSemantics: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                SeloValidade(o.validadeFim),
                if (maisBarato)
                  Etiqueta('Mais barato ${switch (o.porUnidadeTipo) { 'kg' => 'por kg', 'l' => 'por litro', _ => 'por unidade' }}',
                      cor: c.onSecondaryContainer, fundo: c.secondaryContainer),
                if (o.atacado) Etiqueta('Preço de atacado', cor: c.onTertiaryContainer, fundo: c.tertiaryContainer),
                Text(o.nome,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.25)),
                // Wrap: no card estreito, o "antes" e o "R$ X o kg" descem para a linha de baixo
                Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 6, children: [
                  Text(valor == null ? 'Preço no mercado' : reais(valor), style: fredoka(valor == null ? 15 : 20, cor: context.corPreco)),
                  if (o.precoDe != null)
                    Text(reais(o.precoDe!),
                        style: TextStyle(fontSize: 12, color: c.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                  if (unidade != null) Text(unidade, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
                ]),
                if (etiquetaClube != null) Etiqueta(etiquetaClube),
                // até 2 linhas no card; o texto todo na tela da oferta
                if (o.condicaoCurta != null) Etiqueta(o.condicaoCurta!, cor: c.onTertiaryContainer, fundo: c.tertiaryContainer, linhas: 2),
                Text(mostrarMercado ? '${o.redeNome} · até ${diaMes(o.validadeFim)}' : 'até ${diaMes(o.validadeFim)}',
                    style: TextStyle(fontSize: 12, color: c.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            // o botão no pé do card: na grade, os dois cards da linha ficam com ele na mesma altura
            const Spacer(),
            BotaoAdicionar(o),
          ]),
        ),
      ),
    );
  }
}

/// Tons de cinza (luminância), para as categorias não escolhidas no filtro.
const _cinza = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

/// Filtro por categoria (Início e Busca): bolinhas com o ícone (os mesmos do "Sem foto"), "Todas" primeiro.
class FiltroCategoria extends StatelessWidget {
  const FiltroCategoria({super.key, required this.marcadas, required this.onMudar});

  /// Categorias marcadas (vazio = todas). Tocar marca ou desmarca; "Todas" limpa.
  final Set<String> marcadas;
  final ValueChanged<Set<String>> onMudar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    Widget bolinha(String? categoria) {
      final marcada = categoria == null ? marcadas.isEmpty : marcadas.contains(categoria);
      final colorida = marcadas.isEmpty || marcada;
      return Semantics(
        button: true,
        selected: marcada,
        label: categoria ?? 'Todas as categorias',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onMudar(categoria == null
              ? {}
              : marcada
                  ? ({...marcadas}..remove(categoria))
                  : {...marcadas, categoria}),
          child: SizedBox(
            width: 64,
            child: Column(spacing: 4, children: [
              // bolinha branca com o emoji (como no protótipo); a marcada ganha a borda e o fundo da cor do app
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marcada ? c.primaryContainer : c.surface,
                  border: Border.all(color: marcada ? c.primary : c.outlineVariant, width: marcada ? 2 : 1),
                ),
                // sem filtro, todas coloridas; com alguma marcada, só as marcadas coloridas e as outras em cinza
                child: ColorFiltered(
                  colorFilter: colorida ? const ColorFilter.mode(Colors.transparent, BlendMode.dst) : _cinza,
                  child: Opacity(
                    opacity: colorida ? 1 : 0.55,
                    child: Text(categoria == null ? '🏷️' : iconeDaCategoria(categoria), style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
              Text(categoria?.split(' ').first ?? 'Todas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: marcada ? FontWeight.w800 : FontWeight.w600, color: marcada ? c.primary : null)),
            ]),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [bolinha(null), for (final cat in categoriasPrincipais) bolinha(cat)]),
    );
  }
}

/// "Ver mais ofertas" no fim de uma lista paginada.
class VerMais extends StatelessWidget {
  const VerMais({super.key, required this.carregando, required this.onPressed});
  final bool carregando;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: carregando
              ? const CircularProgressIndicator()
              : OutlinedButton(onPressed: onPressed, child: const Text('Ver mais ofertas')),
        ),
      );
}

/// Mensagem de erro com "Tentar de novo".
class Erro extends StatelessWidget {
  const Erro({super.key, required this.onTentar, this.texto = 'Não conseguimos carregar as ofertas.'});
  final VoidCallback onTentar;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          Text(texto, textAlign: TextAlign.center),
          FilledButton(onPressed: onTentar, child: const Text('Tentar de novo')),
        ]),
      );
}
