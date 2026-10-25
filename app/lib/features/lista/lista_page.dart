import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';
import 'grupos.dart';
import 'lista.dart';

/// Tela 6 do protótipo: a lista deste aparelho, por mercado. Nunca tem anúncio.
class ListaPage extends StatefulWidget {
  const ListaPage({super.key, this.abrirCompartilhar = false});
  final bool abrirCompartilhar;

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  @override
  void initState() {
    super.initState();
    Lista.minha.carregar();
    if (widget.abrirCompartilhar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Lista.minha.quantidadeTotal > 0) compartilhar(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Lista.minha,
        builder: (context, _) {
          final l = Lista.minha;
          final n = l.quantidadeTotal;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Minha lista'),
              actions: [
                if (n > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonalIcon(
                        onPressed: () => compartilhar(context), icon: const Icon(Icons.share_outlined), label: const Text('Compartilhar')),
                  ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: l.carregar,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
                if (n == 0 && l.carregando)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()))
                else if (n == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(spacing: 16, children: [
                      Text('Sua lista tá vazia.', style: fredoka(22)),
                      const Text('Bora dar uma olhada nas ofertas de hoje?', textAlign: TextAlign.center),
                      FilledButton(onPressed: () => context.go('/'), child: const Text('Ver ofertas de hoje')),
                    ]),
                  )
                else ...[
                  Text('$n ${n == 1 ? 'item' : 'itens'} em ${l.mercados} ${l.mercados == 1 ? 'mercado' : 'mercados'}',
                      style: TextStyle(color: context.cores.onSurfaceVariant)),
                  if (l.nomeDono != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Compartilhada como “Lista da ${l.nomeDono}”. Você vê na hora o que já foi pro carrinho.',
                          style: TextStyle(fontSize: 13, color: context.cores.primary)),
                    ),
                  const SizedBox(height: 12),
                  AvisoListaSalva(l),
                  GruposDaLista(l),
                  TextButton.icon(
                      onPressed: () => context.go('/'), icon: const Icon(Icons.add), label: const Text('Adicionar mais ofertas')),
                  TextButton.icon(
                    onPressed: () => _esvaziar(context),
                    style: TextButton.styleFrom(foregroundColor: context.cores.error),
                    icon: const Icon(Icons.remove_shopping_cart_outlined),
                    label: const Text('Esvaziar lista'),
                  ),
                ],
                if (l.erro) Erro(onTentar: l.carregar, texto: 'Não conseguimos carregar a lista.'),
              ]),
            ),
          );
        },
      );

  Future<void> _esvaziar(BuildContext context) async {
    final n = Lista.minha.quantidadeTotal;
    final sim = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Esvaziar a lista?'),
        content: Text('${n == 1 ? 'O item sai' : 'Os $n itens saem'} da lista. Quem recebeu o link continua com ele e vê a '
            'lista vazia. Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(backgroundColor: c.cores.error, foregroundColor: c.cores.onError),
              child: const Text('Esvaziar')),
        ],
      ),
    );
    if (sim != true || !context.mounted) return;
    try {
      await Lista.minha.esvaziar();
      if (context.mounted) avisar(context, 'Lista esvaziada', verLista: false);
    } catch (_) {
      if (context.mounted) avisar(context, 'Não deu para esvaziar agora. Confira a internet e tente de novo.', verLista: false);
    }
  }
}

/// Folha "Compartilhar lista": permissão, nome, copiar link ou WhatsApp.
Future<void> compartilhar(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _Compartilhar(),
    );

class _Compartilhar extends StatefulWidget {
  const _Compartilhar();

  @override
  State<_Compartilhar> createState() => _CompartilharState();
}

class _CompartilharState extends State<_Compartilhar> {
  var _permissao = 'marcar';
  late final _nome = TextEditingController(text: Lista.minha.nomeDono ?? '');

  String get _link {
    return linkDoSite('/l/${Lista.minha.codigos?[_permissao] ?? ''}');
  }

  /// Sem internet o nome fica para depois: copiar o link e o WhatsApp funcionam mesmo assim.
  Future<void> _salvarNome() async {
    try {
      if (_nome.text.trim() != (Lista.minha.nomeDono ?? '')) await Lista.minha.nomear(_nome.text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
          Text('Compartilhar lista', style: fredoka(22)),
          const Text('É sempre o mesmo link: quem receber vê a lista atualizada, separada por mercado.'),
          RadioGroup<String>(
            groupValue: _permissao,
            onChanged: (v) => setState(() => _permissao = v!),
            child: const Column(children: [
              RadioListTile(value: 'ver', title: Text('Só ver a lista'), subtitle: Text('Bom para mandar para quem vai ao mercado')),
              RadioListTile(
                  value: 'marcar', title: Text('Ver e marcar o que já pegou'), subtitle: Text('Você acompanha o que já está no carrinho')),
            ]),
          ),
          TextField(
            controller: _nome,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Seu nome (aparece como “Lista da …”)', border: OutlineInputBorder()),
          ),
          SelectableText(_link, style: TextStyle(color: context.cores.onSurfaceVariant)),
          Row(spacing: 8, children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _salvarNome();
                  await Clipboard.setData(ClipboardData(text: _link));
                  if (context.mounted) {
                    Navigator.pop(context);
                    avisar(context, 'Link copiado', verLista: false);
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar link'),
              ),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: () async {
                  await _salvarNome();
                  final texto = 'Minha lista de compras no Promoção na Mão: $_link';
                  await launchUrl(Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}'));
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.send),
                label: const Text('WhatsApp'),
              ),
            ),
          ]),
          Center(
            child: TextButton.icon(
              onPressed: () => _apagar(context),
              style: TextButton.styleFrom(foregroundColor: context.cores.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Apagar minha lista'),
            ),
          ),
        ]),
      );

  Future<void> _apagar(BuildContext context) async {
    final sim = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Apagar a lista inteira?'),
        content: const Text('Quem recebeu o link também deixa de ver. Não dá para desfazer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              style: FilledButton.styleFrom(backgroundColor: c.cores.error, foregroundColor: c.cores.onError),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (sim != true || !context.mounted) return;
    try {
      await Lista.minha.apagar();
      if (context.mounted) {
        Navigator.pop(context);
        avisar(context, 'Lista apagada', verLista: false);
      }
    } catch (_) {
      if (context.mounted) avisar(context, 'Não deu para apagar agora. Confira a internet e tente de novo.', verLista: false);
    }
  }
}
