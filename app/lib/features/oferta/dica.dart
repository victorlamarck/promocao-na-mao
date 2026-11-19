import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics.dart';
import '../../core/tema.dart';

/// Dica de uma vez só (sino e gráfico de preço na tela da oferta): aparece na 1ª vez, fica marcada como vista
/// no aparelho, some com um toque e nunca cobre a tela. Eventos dica_vista e dica_usada (tocou na [acao]).
class Dica extends StatefulWidget {
  const Dica({super.key, required this.id, required this.icone, required this.texto, this.acao, this.onAcao,
      this.margem = const EdgeInsets.only(bottom: 12)});

  /// Nome da dica no Analytics e na chave guardada (`dica_<id>`).
  final String id;
  final IconData icone;
  final String texto;
  final String? acao;
  final VoidCallback? onAcao;

  /// Espaço em volta só enquanto a dica aparece.
  final EdgeInsets margem;

  @override
  State<Dica> createState() => _DicaState();
}

class _DicaState extends State<Dica> {
  var _mostrar = false;

  @override
  void initState() {
    super.initState();
    _talvezMostrar();
  }

  Future<void> _talvezMostrar() async {
    final prefs = await SharedPreferences.getInstance();
    final chave = 'dica_${widget.id}';
    if (!mounted || prefs.getBool(chave) == true) return;
    await prefs.setBool(chave, true); // vista já ao aparecer: sair da tela sem fechar não mostra de novo
    if (!mounted) return;
    setState(() => _mostrar = true);
    evento('dica_vista', {'dica': widget.id});
  }

  void _fechar() => setState(() => _mostrar = false);

  @override
  Widget build(BuildContext context) {
    if (!_mostrar) return const SizedBox.shrink();
    final c = context.cores;
    return Padding(
      padding: widget.margem,
      child: Card(
        color: c.primaryContainer,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: _fechar,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
            child: Row(spacing: 10, children: [
              Icon(widget.icone, color: c.onPrimaryContainer),
              Expanded(child: Text(widget.texto, style: TextStyle(color: c.onPrimaryContainer, fontSize: 14))),
              if (widget.acao case final acao?)
                TextButton(
                  onPressed: () {
                    _fechar();
                    evento('dica_usada', {'dica': widget.id});
                    widget.onAcao?.call();
                  },
                  child: Text(acao),
                ),
              IconButton(
                tooltip: 'Fechar dica',
                icon: Icon(Icons.close, size: 20, color: c.onPrimaryContainer),
                onPressed: _fechar,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
