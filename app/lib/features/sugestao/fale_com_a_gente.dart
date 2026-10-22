import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/tema.dart';
import '../../core/widgets.dart';

/// "Fale com a gente": sugestão ou problema no app, gravado na tabela sugestao (migration 19 do privado).
/// O dev lê no painel do Supabase. Contato opcional, só para quem quer resposta.
Future<void> faleComAGente(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // o teclado não cobre o botão Enviar
      showDragHandle: true,
      builder: (_) => const _FaleComAGente(),
    );

class _FaleComAGente extends StatefulWidget {
  const _FaleComAGente();

  @override
  State<_FaleComAGente> createState() => _FaleComAGenteState();
}

class _FaleComAGenteState extends State<_FaleComAGente> {
  var _tipo = 'sugestao';
  var _enviando = false;
  final _texto = TextEditingController();
  final _contato = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    _contato.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_texto.text.trim().length < 3) return avisar(context, 'Escreva um pouco mais, por favor.', verLista: false);
    setState(() => _enviando = true);
    try {
      await Supabase.instance.client.rpc('enviar_sugestao', params: {
        'tipo': _tipo,
        'texto': _texto.text,
        'contato': _contato.text,
        'versao': versaoDoApp,
        'plataforma': kIsWeb ? 'web' : defaultTargetPlatform.name,
      });
      if (!mounted) return;
      avisar(context, 'Obrigado! Recebemos sua mensagem.', verLista: false);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enviando = false);
      avisar(context, 'Não deu para enviar agora. Confira a internet e tente de novo.', verLista: false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 16, children: [
          Text('Fale com a gente', style: fredoka(22)),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'sugestao', label: Text('Sugestão')),
                ButtonSegment(value: 'erro', label: Text('Problema no app')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
          ),
          TextField(
            controller: _texto,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 1000, // limite do banco
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _tipo == 'erro' ? 'O que aconteceu? Em qual tela?' : 'O que podemos melhorar? Falta algum mercado?',
              border: const OutlineInputBorder(),
            ),
          ),
          TextField(
            controller: _contato,
            maxLength: 120, // limite do banco
            decoration: const InputDecoration(
              labelText: 'Seu WhatsApp ou e-mail (opcional)',
              helperText: 'Só se quiser resposta.',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _enviando ? null : _enviar, child: Text(_enviando ? 'Enviando…' : 'Enviar')),
          ),
        ]),
      );
}
