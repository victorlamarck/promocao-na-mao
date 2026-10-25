import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/busca/busca_page.dart';
import '../features/inicio/inicio_page.dart';
import '../features/lista/lista.dart';
import '../features/lista/lista_page.dart';
import '../features/lista/lista_recebida_page.dart';
import '../features/mercado/mercado_page.dart';
import '../features/mercado/mercados_page.dart';
import '../features/oferta/oferta_page.dart';
import 'modelos.dart';

// Cada tela tem endereço próprio no web: /oferta/123 e /l/<código> podem ser compartilhados no WhatsApp.
final rotas = GoRouter(
    // Links do site vêm com barra no fim (/mercado/big-mais/); as rotas do app não têm.
    redirect: (_, s) => s.uri.path.length > 1 && s.uri.path.endsWith('/') ? s.uri.path.substring(0, s.uri.path.length - 1) : null,
    routes: [
  // Uma pilha por aba: trocar de aba e voltar mantém a tela como estava (rolagem, busca, filtros).
  StatefulShellRoute(
    builder: (_, _, abas) => _ComAbas(abas),
    // O mesmo do StatefulShellRoute.indexedStack, mais o ExcludeFocus: a aba escondida solta o teclado.
    navigatorContainerBuilder: (_, abas, telas) => IndexedStack(index: abas.currentIndex, children: [
      for (final (i, tela) in telas.indexed)
        ExcludeFocus(excluding: i != abas.currentIndex, child: TickerMode(enabled: i == abas.currentIndex, child: tela)),
    ]),
    branches: [
      StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const SafeArea(child: InicioPage()))]),
      StatefulShellBranch(routes: [
        GoRoute(path: '/buscar', builder: (_, s) => SafeArea(child: BuscaPage(termoInicial: s.uri.queryParameters['q'] ?? ''))),
      ]),
      StatefulShellBranch(routes: [GoRoute(path: '/mercados', builder: (_, _) => const MercadosPage())]),
      StatefulShellBranch(routes: [
        GoRoute(path: '/lista', builder: (_, s) => ListaPage(abrirCompartilhar: s.uri.queryParameters['compartilhar'] == '1')),
      ]),
    ],
  ),
  // Detalhes ficam fora das abas (tela cheia, sem a barra): abrem por cima com push e o voltar do Android
  // volta à aba de onde saíram, do jeito que ela estava. Por link abrem sozinhos, com o botão Início.
  GoRoute(path: '/mercado/:slug', builder: (_, s) => MercadoPage(slug: s.pathParameters['slug']!)),
  GoRoute(path: '/oferta/:id', builder: (_, s) => OfertaPage(id: int.tryParse(s.pathParameters['id']!) ?? 0, oferta: s.extra as Oferta?)),
  GoRoute(path: '/l/:codigo', builder: (_, s) => ListaRecebidaPage(codigo: s.pathParameters['codigo']!)),
]);

/// As 4 abas do protótipo: Início, Buscar, Mercados, Lista.
class _ComAbas extends StatelessWidget {
  const _ComAbas(this.abas);
  final StatefulNavigationShell abas;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: abas,
        bottomNavigationBar: ListenableBuilder(
          listenable: Lista.minha,
          builder: (context, _) {
            // quantos itens tem na lista, no ícone da aba
            final n = Lista.minha.quantidadeTotal;
            Widget icone(IconData i) => Badge.count(count: n, isLabelVisible: n > 0, child: Icon(i));
            return NavigationBar(
              selectedIndex: abas.currentIndex,
              // tocar na aba que já está aberta volta ao começo dela
              onDestinationSelected: (i) => abas.goBranch(i, initialLocation: i == abas.currentIndex),
              destinations: [
                const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
                const NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
                const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Mercados'),
                NavigationDestination(icon: icone(Icons.checklist_outlined), selectedIcon: icone(Icons.checklist), label: 'Lista'),
              ],
            );
          },
        ),
      );
}
