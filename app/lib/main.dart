import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/abertura.dart';
import 'core/config.dart';
import 'core/rotas.dart';
import 'core/tema.dart';
import 'features/anuncios/admob.dart' if (dart.library.js_interop) 'features/anuncios/adsense_web.dart';
import 'features/avisos/avisos.dart';
import 'features/boas_vindas/boas_vindas.dart';
import 'features/lista/lista.dart';
import 'firebase_options_dev.dart' as firebase_dev;
import 'firebase_options_prod.dart' as firebase_prod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // endereços sem "#": /oferta/123, /l/<código>
  final faltando = configFaltando();
  if (faltando.isNotEmpty) throw StateError('config/$flavor.json sem: ${faltando.join(', ')}');
  if (appFlavor != null && appFlavor != flavor) throw StateError('--flavor $appFlavor com config/$flavor.json');
  // Gerados pelo flutterfire configure, um por projeto Firebase (ver docs/app.md).
  await Firebase.initializeApp(
      options: ehProd ? firebase_prod.DefaultFirebaseOptions.currentPlatform : firebase_dev.DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    // Crashlytics: travamentos chegam ao console do Firebase do flavor (dev ou prod).
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (erro, pilha) {
      FirebaseCrashlytics.instance.recordError(erro, pilha, fatal: true);
      return true;
    };
  }
  final novo = await primeiraVez(); // antes do Supabase e do cache gravarem algo
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseChavePublica);
  await carregarAparencia();
  Lista.minha.iniciar(); // sem await: o app abre enquanto a lista carrega
  iniciarAdsense();
  iniciarAvisos(); // sem await: tocar numa notificação abre o mercado quando o app já está de pé
  _telasNoAnalytics();
  // aberto por link (/l/..., /oferta/...) ou no navegador: direto para a tela
  final pular = kIsWeb || rotas.routeInformationProvider.value.uri.path != '/';
  runApp(ListenableBuilder(
    listenable: Listenable.merge([corDoApp, temaDoApp]),
    builder: (_, _) => MaterialApp.router(
      title: 'Promoção na Mão',
      debugShowCheckedModeBanner: false,
      theme: temaApp(corDoApp.value, Brightness.light),
      darkTheme: temaApp(corDoApp.value, Brightness.dark),
      themeMode: temaDoApp.value,
      routerConfig: rotas,
      builder: (_, filho) => Abertura(
        pular: pular,
        child: BoasVindas(
          mostrar: novo && !pular,
          // faixa "DEV" no canto para não confundir com o app publicado
          child: ehProd ? filho! : Banner(message: 'DEV', location: BannerLocation.topEnd, child: filho!),
        ),
      ),
    ),
  ));
}

/// Analytics: uma "tela vista" por troca de rota, com o MOLDE do caminho ("/l/:codigo"),
/// nunca o caminho de verdade, que levaria o código secreto da lista.
void _telasNoAnalytics() {
  String? ultima;
  rotas.routerDelegate.addListener(() {
    final tela = rotas.routerDelegate.currentConfiguration.fullPath;
    if (tela.isEmpty || tela == ultima) return;
    ultima = tela;
    FirebaseAnalytics.instance.logScreenView(screenName: tela);
  });
}
