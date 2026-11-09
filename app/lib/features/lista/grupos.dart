import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import '../avisos/avisos.dart';
import 'lista.dart';

/// Quanto dá a compra num mercado: preço × quantidade dos itens com preço; com clube usa o preço de clube
/// quando o item tem (null se nenhum tem). Itens anotados à mão (sem preço) ficam fora.
// shortcut: "leve 3 pague 2" conta como preço cheio por unidade; ajustar se o extrator passar a dar o preço da regra.
(double, double?) totalDoMercado(List<ItemLista> itens) {
  final comPreco = itens.where((i) => i.preco != null);
  final total = comPreco.fold<double>(0.0, (t, i) => t + i.preco! * i.quantidade);
  if (!comPreco.any((i) => i.precoClube != null)) return (total, null);
  return (total, comPreco.fold<double>(0.0, (t, i) => t + (i.precoClube ?? i.preco!) * i.quantidade));
}

/// Itens agrupados por mercado; anotados à mão por último. Usado na Minha lista e na lista recebida.
class GruposDaLista extends StatelessWidget {
  const GruposDaLista(this.lista, {super.key, this.semMercado = 'Sem mercado definido'});
  final Lista lista;
  final String semMercado;

  @override
  Widget build(BuildContext context) {
    final grupos = <int?, List<ItemLista>>{};
    for (final i in lista.itens) {
      (grupos[i.redeId] ??= []).add(i);
    }
    // Mercados com mais itens primeiro; "sem mercado" no fim.
    final ordem = grupos.keys.toList()
      ..sort((a, b) => a == null ? 1 : b == null ? -1 : grupos[b]!.length.compareTo(grupos[a]!.length));
    return Column(children: [for (final rede in ordem) _Grupo(lista, grupos[rede]!, semMercado)]);
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo(this.lista, this.itens, this.semMercado);
  final Lista lista;
  final List<ItemLista> itens;
  final String semMercado;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final primeiro = itens.first;
    final pegos = itens.where((i) => i.pego).length;
    final validades = itens.map((i) => i.validadeFim).whereType<DateTime>().toList()..sort();
    final sub = primeiro.redeId == null
        ? 'Itens anotados à mão'
        : validades.isEmpty
            ? ''
            : 'Ofertas valem até ${diaMes(validades.first)}';
    final (total, totalClube) = totalDoMercado(itens);
    final clube = Mercado.de(primeiro.redeSlug).clube;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          ListTile(
            leading: AvatarMercado(primeiro.redeSlug, tamanho: 40),
            title: Text(primeiro.redeNome ?? semMercado, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (sub.isNotEmpty) Text(sub),
              if (total > 0)
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'Total ${reais(total)}', style: TextStyle(fontWeight: FontWeight.w800, color: context.corPreco)),
                  if (totalClube != null && totalClube < total) TextSpan(text: ' · ${reais(totalClube)} com ${clube ?? 'clube'}'),
                ])),
            ]),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$pegos/${itens.length}', style: TextStyle(fontWeight: FontWeight.w800, color: c.onSurfaceVariant)),
              if (primeiro.redeNome != null)
                IconButton(
                  tooltip: 'Ver ${primeiro.redeNome} no mapa',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => launchUrl(Uri.parse(
                      'https://www.google.com/maps/search/${Uri.encodeComponent('${primeiro.redeNome} Governador Valadares')}')),
                ),
            ]),
          ),
          for (final i in itens) _Item(lista, i),
        ]),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.lista, this.item);
  final Lista lista;
  final ItemLista item;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant))),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        Checkbox(
          value: item.pego,
          semanticLabel: item.pego ? 'Desmarcar ${item.texto}' : 'Marcar ${item.texto} como pego',
          onChanged: lista.podeMarcar ? (v) => tentarNaLista(context, () => lista.marcar(item, v!)) : null,
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
            Text(item.texto,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: item.pego ? TextDecoration.lineThrough : null,
                  color: item.pego ? c.onSurfaceVariant : null,
                )),
            if (!item.pego) SeloValidade(item.validadeFim),
          ]),
        ),
        // Sino do produto (o mesmo da tela da oferta); some depois de pego, para não apertar a linha à toa.
        if (item.produtoCodigo != null && !item.pego) BotaoAviso.produto(codigo: item.produtoCodigo!, nome: item.texto),
        if (lista.podeEditar)
          Contador(quantidade: item.quantidade, nome: item.texto, onMudar: (q) => tentarNaLista(context, () => lista.mudarQuantidade(item, q)))
        else
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('${item.quantidade}×', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
      ]),
    );
  }
}

/// "Quanto a lista sai em cada mercado": só com 2 mercados ou mais para comparar. O selo "Mais barato" vai para o
/// 1º da ordem do banco (mais itens encontrados, depois menor total) só se ele achou todos os itens comparáveis:
/// mercado que tem menos coisa não ganha selo por ficar mais barato.
class ComparacaoDaLista extends StatelessWidget {
  const ComparacaoDaLista(this.lista, {super.key});
  final Lista lista;

  @override
  Widget build(BuildContext context) {
    final m = lista.comparacao;
    if (m.length < 2) return const SizedBox.shrink();
    final c = context.cores;
    final n = m.first.itens;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text('Quanto a lista sai em cada mercado', style: fredoka(18)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            child: Text(
                'Pelo menor preço de hoje de ${n == 1 ? 'cada produto' : 'cada um dos $n produtos'} da lista que achamos em outros encartes.',
                style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
          ),
          for (final (i, r) in m.indexed)
            ListTile(
              dense: true,
              leading: AvatarMercado(r.redeSlug, tamanho: 36),
              title: Row(spacing: 6, children: [
                Flexible(child: Text(r.redeNome, style: const TextStyle(fontWeight: FontWeight.w700))),
                if (i == 0 && r.encontrados == r.itens)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Text('Mais barato',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.onPrimaryContainer)),
                  ),
              ]),
              subtitle: Text(r.encontrados == r.itens ? 'Todos os itens' : '${r.encontrados} de ${r.itens} itens'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(reais(r.total), style: TextStyle(fontWeight: FontWeight.w800, color: context.corPreco)),
                if (r.totalClube != null && r.totalClube! < r.total)
                  Text('${reais(r.totalClube!)} com ${Mercado.de(r.redeSlug).clube ?? 'clube'}', style: const TextStyle(fontSize: 12)),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// "Sem internet": a lista na tela é a última salva no aparelho; marcar volta quando a conexão voltar.
class AvisoListaSalva extends StatelessWidget {
  const AvisoListaSalva(this.lista, {super.key});
  final Lista lista;

  @override
  Widget build(BuildContext context) => !lista.salva
      ? const SizedBox.shrink()
      : Card(
          color: context.cores.secondaryContainer,
          child: ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Sem internet'),
            subtitle: Text('Mostrando a lista salva às ${_dd(lista.atualizadaEm!.hour)}:${_dd(lista.atualizadaEm!.minute)}. '
                'Para marcar, espere a conexão voltar.'),
            trailing: TextButton(onPressed: lista.carregar, child: const Text('Tentar')),
          ),
        );

  static String _dd(int n) => n.toString().padLeft(2, '0');
}
