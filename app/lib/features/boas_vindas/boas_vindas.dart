import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/tema.dart';

// Garante o aparelho "não vazio" mesmo se a primeira abertura foi sem internet (nada mais gravado).
const _chave = 'boas_vindas_vistas';

/// Primeira vez neste aparelho? Lido antes de qualquer coisa gravar no aparelho: quem já usava o app
/// tem o cache das ofertas, a lista ou a cor guardados e não vê as boas-vindas ao atualizar.
Future<bool> primeiraVez() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getKeys().isEmpty;
}

/// Três telas explicando o app, por cima da Início, só na primeira abertura (a Abertura passa por cima delas).
/// "Pular" em todas; as ofertas já carregam por baixo.
class BoasVindas extends StatefulWidget {
  const BoasVindas({super.key, required this.mostrar, required this.child});
  final bool mostrar;
  final Widget child;

  static const telas = [
    (
      Icons.local_offer_outlined,
      'As ofertas de GV numa lista só',
      'Os encartes dos supermercados de Governador Valadares num lugar só, todo dia. Mostramos só o que vale hoje.',
    ),
    (
      Icons.compare_arrows,
      'Compare antes de ir',
      'Busque o produto e veja o preço do kg ou do litro em cada mercado. O selo "Mais barato" mostra onde compensa.',
    ),
    (
      Icons.checklist,
      'Lista de compras compartilhada',
      'Monte a lista separada por mercado e mande o link no WhatsApp. Quem vai ao mercado marca o que pegou e você vê na hora.',
    ),
  ];

  @override
  State<BoasVindas> createState() => _BoasVindasState();
}

class _BoasVindasState extends State<BoasVindas> {
  late var _visivel = widget.mostrar;
  final _paginas = PageController();
  var _pagina = 0;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  Future<void> _fechar() async {
    setState(() => _visivel = false);
    await (await SharedPreferences.getInstance()).setBool(_chave, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visivel) return widget.child;
    final c = context.cores;
    final ultima = _pagina == BoasVindas.telas.length - 1;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: c.surface,
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _fechar, child: const Text('Pular')),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _paginas,
                      onPageChanged: (i) => setState(() => _pagina = i),
                      children: [
                        for (final (icone, titulo, texto) in BoasVindas.telas)
                          Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              child: Column(
                                spacing: 20,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                                    child: Icon(icone, size: 72, color: c.onPrimaryContainer),
                                  ),
                                  Text(
                                    titulo,
                                    textAlign: TextAlign.center,
                                    style: fredoka(26, cor: c.onSurface),
                                  ),
                                  Text(
                                    texto,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, height: 1.4, color: c.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'Tela ${_pagina + 1} de ${BoasVindas.telas.length}',
                          child: Row(
                            spacing: 6,
                            children: [
                              for (var i = 0; i < BoasVindas.telas.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: i == _pagina ? 22 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _pagina ? c.primary : c.outlineVariant,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: ultima
                              ? _fechar
                              : () => _paginas.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                          child: Text(ultima ? 'Começar' : 'Próximo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
