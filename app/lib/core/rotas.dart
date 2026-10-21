import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/busca/busca_page.dart';
import '../features/inicio/inicio_page.dart';
import '../features/lista/lista_page.dart';
import '../features/lista/lista_recebida_page.dart';
import '../features/mercado/mercado_page.dart';
import '../features/mercado/mercados_page.dart';
import '../features/oferta/oferta_page.dart';

// Cada tela tem endereço próprio no web: /oferta/123 e /l/<código> podem ser compartilhados no WhatsApp.
final rotas = GoRouter(
    // Links do site vêm com barra no fim (/mercado/big-mais/); as rotas do app não têm.
    redirect: (_, s) => s.uri.path.length > 1 && s.uri.path.endsWith('/') ? s.uri.path.substring(0, s.uri.path.length - 1) : null,
    routes: [
  ShellRoute(
    builder: (context, state, filho) => _ComAbas(caminho: state.uri.path, child: filho),
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SafeArea(child: InicioPage())),
      GoRoute(path: '/buscar', builder: (_, s) => SafeArea(child: BuscaPage(termoInicial: s.uri.queryParameters['q'] ?? ''))),
      GoRoute(path: '/mercados', builder: (_, _) => const MercadosPage()),
      GoRoute(path: '/lista', builder: (_, s) => ListaPage(abrirCompartilhar: s.uri.queryParameters['compartilhar'] == '1')),
    ],
  ),
  GoRoute(path: '/mercado/:slug', builder: (_, s) => MercadoPage(slug: s.pathParameters['slug']!)),
  GoRoute(path: '/oferta/:id', builder: (_, s) => OfertaPage(id: int.tryParse(s.pathParameters['id']!) ?? 0)),
  GoRoute(path: '/l/:codigo', builder: (_, s) => ListaRecebidaPage(codigo: s.pathParameters['codigo']!)),
]);

/// As 4 abas do protótipo: Início, Buscar, Mercados, Lista.
class _ComAbas extends StatelessWidget {
  const _ComAbas({required this.caminho, required this.child});
  final String caminho;
  final Widget child;

  static const _caminhos = ['/', '/buscar', '/mercados', '/lista'];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _caminhos.indexOf(caminho).clamp(0, 3),
          onDestinationSelected: (i) => context.go(_caminhos[i]),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Mercados'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Lista'),
          ],
        ),
      );
}
