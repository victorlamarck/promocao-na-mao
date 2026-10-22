import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/rotas.dart';

/// Avisos push (docs/app.md#avisos-de-ofertas-novas-push), sem login e sem guardar o aparelho no nosso banco:
/// - "Ofertas novas no mercado": sino na tela do mercado, tópico `ofertas-<slug>`;
/// - "Produto em oferta": sino na tela da oferta, tópico `produto-<codigo do catálogo>` (migration 20 do privado).
/// A esteira de dados avisa o tópico depois de importar.
/// shortcut: só Android por enquanto; iPhone precisa da chave APNs (conta Apple) e o web não usa tópicos.
bool get avisosDisponiveis => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Um tipo de aviso: os valores ligados neste aparelho (slugs ou códigos), guardados em [_chave].
class TipoAviso {
  TipoAviso._(this._chave, this._prefixo);
  final String _chave, _prefixo;
  final ligados = ValueNotifier<Set<String>>({});

  String topico(String valor) => '$_prefixo$valor';

  Future<void> _carregar(SharedPreferences prefs) async => ligados.value = (prefs.getStringList(_chave) ?? []).toSet();

  /// Liga ou desliga. Devolve false se a pessoa negou a permissão de notificação.
  Future<bool> alternar(String valor) async {
    final ligar = !ligados.value.contains(valor);
    final fcm = FirebaseMessaging.instance;
    if (ligar) {
      final p = await fcm.requestPermission(); // Android 13+ pergunta; antes já vem liberado
      if (p.authorizationStatus == AuthorizationStatus.denied) return false;
      await fcm.subscribeToTopic(topico(valor));
    } else {
      await fcm.unsubscribeFromTopic(topico(valor));
    }
    final novo = {...ligados.value};
    ligar ? novo.add(valor) : novo.remove(valor);
    ligados.value = novo;
    await (await SharedPreferences.getInstance()).setStringList(_chave, novo.toList());
    return true;
  }
}

final avisoMercado = TipoAviso._('avisos_mercados', 'ofertas-');
// shortcut: desligar só pela tela de uma oferta do produto; uma lista "meus avisos" quando alguém pedir.
final avisoProduto = TipoAviso._('avisos_produtos', 'produto-');

Future<void> iniciarAvisos() async {
  if (!avisosDisponiveis) return;
  final prefs = await SharedPreferences.getInstance();
  await avisoMercado._carregar(prefs);
  await avisoProduto._carregar(prefs);
  // Tocou na notificação: abre o mercado ou a oferta (a esteira manda data.rota).
  FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
  final inicial = await FirebaseMessaging.instance.getInitialMessage();
  if (inicial != null) _abrir(inicial);
}

void _abrir(RemoteMessage m) {
  final rota = m.data['rota'];
  if (rota is String && (rota.startsWith('/mercado/') || rota.startsWith('/oferta/'))) rotas.push(rota);
}

/// Sino: na tela do mercado (ofertas novas) e na da oferta (produto em oferta).
class BotaoAviso extends StatelessWidget {
  BotaoAviso.mercado({super.key, required String slug, required String nome})
      : tipo = avisoMercado,
        valor = slug,
        ligar = 'Avisar quando sair oferta nova do $nome',
        desligar = 'Parar de avisar ofertas novas do $nome',
        ligado = 'Pronto! Avisamos quando sair encarte novo do $nome.',
        desligado = 'Não vamos mais avisar do $nome.';

  BotaoAviso.produto({super.key, required String codigo, required String nome})
      : tipo = avisoProduto,
        valor = codigo,
        ligar = 'Avisar quando $nome estiver em oferta',
        desligar = 'Parar de avisar de $nome',
        ligado = 'Pronto! Avisamos quando $nome entrar em oferta.',
        desligado = 'Não vamos mais avisar de $nome.';

  final TipoAviso tipo;
  final String valor, ligar, desligar, ligado, desligado;

  @override
  Widget build(BuildContext context) => !avisosDisponiveis
      ? const SizedBox.shrink()
      : ValueListenableBuilder(
          valueListenable: tipo.ligados,
          builder: (context, avisados, _) {
            final esta = avisados.contains(valor);
            return IconButton(
              tooltip: esta ? desligar : ligar,
              isSelected: esta,
              icon: const Icon(Icons.notifications_none),
              selectedIcon: const Icon(Icons.notifications_active),
              onPressed: () async {
                final msg = ScaffoldMessenger.of(context);
                try {
                  final ok = await tipo.alternar(valor);
                  msg.showSnackBar(SnackBar(
                      content: Text(!ok
                          ? 'Para avisar, libere as notificações do app nas configurações do celular.'
                          : tipo.ligados.value.contains(valor)
                              ? ligado
                              : desligado)));
                } catch (_) {
                  msg.showSnackBar(const SnackBar(content: Text('Não deu agora. Confira a internet e tente de novo.')));
                }
              },
            );
          },
        );
}
