import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/rotas.dart';

/// Avisos "Ofertas novas no mercado" (docs/app.md#avisos-de-ofertas-novas-push): a pessoa liga o sino
/// na tela do mercado e o app assina o tópico `ofertas-<slug>` do FCM; a esteira de dados avisa o tópico
/// quando entra encarte novo. Sem login e sem guardar o aparelho no nosso banco.
/// shortcut: só Android por enquanto; iPhone precisa da chave APNs (conta Apple) e o web não usa tópicos.
bool get avisosDisponiveis => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

const _chave = 'avisos_mercados';

/// Slugs dos mercados com aviso ligado neste aparelho.
final mercadosAvisados = ValueNotifier<Set<String>>({});

String topico(String slug) => 'ofertas-$slug';

Future<void> iniciarAvisos() async {
  if (!avisosDisponiveis) return;
  mercadosAvisados.value = ((await SharedPreferences.getInstance()).getStringList(_chave) ?? []).toSet();
  // Tocou na notificação: abre o mercado (a esteira manda data.rota = "/mercado/<slug>").
  FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
  final inicial = await FirebaseMessaging.instance.getInitialMessage();
  if (inicial != null) _abrir(inicial);
}

void _abrir(RemoteMessage m) {
  final rota = m.data['rota'];
  if (rota is String && rota.startsWith('/mercado/')) rotas.push(rota);
}

/// Liga ou desliga o aviso de um mercado. Devolve false se a pessoa negou a permissão de notificação.
Future<bool> alternarAviso(String slug) async {
  final ligar = !mercadosAvisados.value.contains(slug);
  final fcm = FirebaseMessaging.instance;
  if (ligar) {
    final p = await fcm.requestPermission(); // Android 13+ pergunta; antes já vem liberado
    if (p.authorizationStatus == AuthorizationStatus.denied) return false;
    await fcm.subscribeToTopic(topico(slug));
  } else {
    await fcm.unsubscribeFromTopic(topico(slug));
  }
  final novo = {...mercadosAvisados.value};
  ligar ? novo.add(slug) : novo.remove(slug);
  mercadosAvisados.value = novo;
  await (await SharedPreferences.getInstance()).setStringList(_chave, novo.toList());
  return true;
}

/// Sino da tela do mercado.
class BotaoAviso extends StatelessWidget {
  const BotaoAviso({super.key, required this.slug, required this.nome});
  final String slug, nome;

  @override
  Widget build(BuildContext context) => !avisosDisponiveis
      ? const SizedBox.shrink()
      : ValueListenableBuilder(
          valueListenable: mercadosAvisados,
          builder: (context, avisados, _) {
            final ligado = avisados.contains(slug);
            return IconButton(
              tooltip: ligado ? 'Parar de avisar ofertas novas do $nome' : 'Avisar quando sair oferta nova do $nome',
              isSelected: ligado,
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications_active),
              onPressed: () async {
                final msg = ScaffoldMessenger.of(context);
                try {
                  final ok = await alternarAviso(slug);
                  msg.showSnackBar(SnackBar(
                      content: Text(!ok
                          ? 'Para avisar, libere as notificações do app nas configurações do celular.'
                          : mercadosAvisados.value.contains(slug)
                              ? 'Pronto! Avisamos quando sair encarte novo do $nome.'
                              : 'Não vamos mais avisar do $nome.')));
                } catch (_) {
                  msg.showSnackBar(const SnackBar(content: Text('Não deu agora. Confira a internet e tente de novo.')));
                }
              },
            );
          },
        );
}
