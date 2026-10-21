import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/tema.dart';
import '../../core/widgets.dart';
import 'grupos.dart';
import 'lista.dart';

/// Tela 7 do protótipo: a lista que alguém compartilhou (`/l/<código>`). Atualiza na hora.
class ListaRecebidaPage extends StatefulWidget {
  const ListaRecebidaPage({super.key, required this.codigo});
  final String codigo;

  @override
  State<ListaRecebidaPage> createState() => _ListaRecebidaPageState();
}

class _ListaRecebidaPageState extends State<ListaRecebidaPage> {
  late final _lista = Lista.recebida(widget.codigo)..carregar();

  @override
  void dispose() {
    _lista.dispose();
    super.dispose();
  }

  static String _ha(DateTime t) {
    final m = DateTime.now().difference(t).inMinutes;
    return m < 1 ? 'agora' : m < 60 ? 'há $m min' : 'há ${m ~/ 60} h';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _lista,
        builder: (context, _) {
          final l = _lista;
          final c = context.cores;
          final quem = l.nomeDono;
          final total = l.itens.length, pegos = l.itens.where((i) => i.pego).length;
          return Scaffold(
            appBar: AppBar(leading: inicioSeAbriuPorLink(context), title: Text(quem == null ? 'Lista compartilhada' : 'Lista da $quem')),
            bottomNavigationBar: l.podeMarcar && total > 0
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        onPressed: () => launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(pegos == total ? 'Terminei as compras da lista! ✔' : 'Terminei as compras. Faltou: ${l.itens.where((i) => !i.pego).map((i) => i.texto).join(', ')}')}')),
                        child: Text(pegos == total ? 'Avisar ${quem ?? 'quem mandou'} que terminei' : 'Avisar que terminei (${total - pegos} faltando)'),
                      ),
                    ),
                  )
                : null,
            body: switch (l) {
              _ when l.erro && l.id == null => Erro(onTentar: l.carregar, texto: 'Não achamos esta lista. Confira o link com quem mandou.'),
              _ when l.id == null => const Center(child: CircularProgressIndicator()),
              _ => RefreshIndicator(
                  onRefresh: l.carregar,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                    Text(
                        '${quem == null ? 'Compartilhada com você' : '$quem compartilhou com você'} · atualizada ${_ha(l.atualizadaEm!)}',
                        style: TextStyle(color: c.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    AvisoListaSalva(l),
                    Text('$pegos de $total itens pegos', style: fredoka(20)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: total == 0 ? 0 : pegos / total, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    Text(
                        l.podeMarcar
                            ? 'Marque o que já pegou. ${quem ?? 'Quem mandou'} vê na hora.'
                            : 'Você pode ver a lista; só quem mandou altera.',
                        style: TextStyle(fontSize: 13, color: c.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    GruposDaLista(l, semMercado: 'Onde preferir'),
                  ]),
                ),
            },
          );
        },
      );
}
