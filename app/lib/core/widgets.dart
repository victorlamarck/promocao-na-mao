import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/lista/lista.dart';
import 'formato.dart';
import 'modelos.dart';
import 'tema.dart';

/// Bolinha com a sigla e a cor do mercado (sem logotipo).
class AvatarMercado extends StatelessWidget {
  const AvatarMercado(this.slug, {super.key, this.tamanho = 48});
  final String? slug;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final m = Mercado.de(slug);
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
  const Etiqueta(this.texto, {super.key, this.cor, this.fundo});
  final String texto;
  final Color? cor, fundo;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: fundo ?? context.cores.primaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Text(texto, style: TextStyle(fontSize: 12, height: 1.35, fontWeight: FontWeight.w600, color: cor ?? context.cores.onPrimaryContainer)),
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

/// "− 2 +" (rótulos para leitor de tela: "Mais um café"). Vai até 999, o limite do banco.
class Contador extends StatelessWidget {
  const Contador({super.key, required this.quantidade, required this.nome, required this.onMudar});
  final int quantidade;
  final String nome;
  final ValueChanged<int> onMudar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      height: 40,
      decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: quantidade == 1 ? 'Tirar $nome da lista' : 'Menos um $nome',
          onPressed: () => onMudar(quantidade - 1),
          icon: Icon(quantidade == 1 ? Icons.delete_outline : Icons.remove, color: c.onPrimary, size: 20),
        ),
        Text('$quantidade', style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
        IconButton(
          tooltip: 'Mais um $nome',
          onPressed: quantidade >= 999 ? null : () => onMudar(quantidade + 1),
          icon: Icon(Icons.add, color: c.onPrimary, size: 20),
        ),
      ]),
    );
  }
}

/// "Adicionar" que vira contador quando a oferta já está na lista.
class BotaoAdicionar extends StatelessWidget {
  const BotaoAdicionar(this.oferta, {super.key, this.largo = false});
  final Oferta oferta;
  final bool largo;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Lista.minha,
        builder: (context, _) {
          final item = Lista.minha.itemDaOferta(oferta.id);
          if (item != null) {
            return Contador(
              quantidade: item.quantidade,
              nome: oferta.nome,
              onMudar: (q) async {
                if (await tentarNaLista(context, () => Lista.minha.mudarQuantidade(item, q)) && q == 0 && context.mounted) {
                  avisar(context, 'Tirado da lista', verLista: false);
                }
              },
            );
          }
          return FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: Size(largo ? double.infinity : 44, largo ? 52 : 40)),
            onPressed: () async {
              try {
                await Lista.minha.adicionar(oferta);
                if (context.mounted) avisar(context, 'Adicionado no ${oferta.redeNome}');
              } catch (_) {
                if (context.mounted) avisar(context, 'Não deu para adicionar agora. Tenta de novo?', verLista: false);
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(largo ? 'Adicionar à lista' : 'Adicionar'),
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
    return Etiqueta(aviso,
        cor: venceu ? context.cores.onErrorContainer : const Color(0xFF5C4300),
        fundo: venceu ? context.cores.errorContainer : const Color(0xFFFFF3C4));
  }
}

/// Card de uma oferta: mercado e validade, nome, preço (o elemento mais forte), clube, "antes", condição, Adicionar.
class CardOferta extends StatelessWidget {
  const CardOferta(this.oferta, {super.key, this.mostrarPorUnidade = false, this.mostrarMercado = true});
  final Oferta oferta;
  final bool mostrarPorUnidade, mostrarMercado;

  @override
  Widget build(BuildContext context) {
    final o = oferta;
    final c = context.cores;
    final clube = Mercado.de(o.redeSlug).clube ?? 'clube';
    final unidade = mostrarPorUnidade ? porUnidade(o.precoReferencia, o.unidadeReferencia) : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/oferta/${o.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
            if (mostrarMercado)
              Row(spacing: 6, children: [
                AvatarMercado(o.redeSlug, tamanho: 10),
                Flexible(
                  child: Text('${o.redeNome} · até ${diaMes(o.validadeFim)}',
                      style: TextStyle(fontSize: 12, color: c.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ),
              ]),
            SeloValidade(o.validadeFim),
            Text(o.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25)),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, spacing: 8, children: [
              Text(o.preco == null ? 'Preço no mercado' : reais(o.preco!), style: fredoka(o.preco == null ? 16 : 22, cor: context.corPreco)),
              if (unidade != null) Text(unidade, style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
            ]),
            if (o.precoClube != null) Etiqueta('${reais(o.precoClube!)} com $clube'),
            if (o.precoDe != null)
              Text.rich(TextSpan(style: TextStyle(fontSize: 12, color: c.onSurfaceVariant), children: [
                const TextSpan(text: 'Antes '),
                TextSpan(text: reais(o.precoDe!), style: const TextStyle(decoration: TextDecoration.lineThrough)),
              ])),
            if (o.condicao != null) Etiqueta(o.condicao!, cor: c.onTertiaryContainer, fundo: c.tertiaryContainer),
            const SizedBox(height: 4),
            BotaoAdicionar(o),
          ]),
        ),
      ),
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
