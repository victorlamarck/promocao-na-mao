import 'package:flutter/foundation.dart';

// Configuração por flavor: cada um é um arquivo em config/ (nada de segredo: a chave do
// Supabase é a PÚBLICA, protegida pelo RLS).
//   flutter run -d chrome --dart-define-from-file=config/dev.json
//   flutter build web --dart-define-from-file=config/prod.json
// Sem arquivo, vale o dev (Supabase local).

const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
const ehProd = flavor == 'prod';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: ehProd ? '' : 'http://127.0.0.1:54321');
const supabaseChavePublica = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY',
    defaultValue: ehProd ? '' : 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH');

/// Versão do app ("0.3.1+10"), enviada junto com as sugestões e os relatos de problema.
/// A esteira Android passa --dart-define=VERSAO=<a do pubspec>; build local fica "dev".
const versaoDoApp = String.fromEnvironment('VERSAO', defaultValue: 'dev');

/// Endereço público do site, para os links compartilhados (vazio: o endereço aberto no navegador).
const appUrl = String.fromEnvironment('APP_URL');

/// Link do site para um caminho do app ("/l/abc", "/oferta/12"): abre no app (App Links) ou no site.
// shortcut: no celular sem APP_URL (dev.json local) usa o site dev; preencher APP_URL se precisar de outro.
String linkDoSite(String caminho) =>
    '${appUrl.isNotEmpty ? appUrl : kIsWeb ? Uri.base.origin : 'https://promocaonamao-f08a7.web.app'}$caminho';

/// AdSense: sem estas duas, espaço sem anúncio vendido mostra "Anuncie aqui".
const adsenseCliente = String.fromEnvironment('ADSENSE_CLIENT'); // ca-pub-...
const adsenseSlot = String.fromEnvironment('ADSENSE_SLOT');

/// AdMob (o AdSense não roda em app): bloco de anúncio do Android. No dev, o bloco de teste do Google.
/// O ID do app AdMob (ADMOB_APP_ID) vai no manifest pelo build.gradle.kts, não aqui.
const admobBloco = String.fromEnvironment('ADMOB_BLOCO', defaultValue: ehProd ? '' : 'ca-app-pub-3940256099942544/6300978111');

/// Contatos do dev (WhatsApp ou formulário): "Anuncie aqui" e "Sugerir mercado".
/// No dev, abrem o WhatsApp sem destinatário; no prod são obrigatórios.
const contatoAnuncie = String.fromEnvironment('CONTATO_ANUNCIE',
    defaultValue: ehProd ? '' : 'https://wa.me/?text=Quero%20anunciar%20no%20Promo%C3%A7%C3%A3o%20na%20M%C3%A3o');
const contatoSugestao = String.fromEnvironment('CONTATO_SUGESTAO',
    defaultValue: ehProd ? '' : 'https://wa.me/?text=Sugest%C3%A3o%20de%20mercado%20para%20o%20Promo%C3%A7%C3%A3o%20na%20M%C3%A3o%3A%20');

/// Nomes da configuração obrigatória que estão vazios (o prod não abre sem eles).
List<String> configFaltando() => {
      'SUPABASE_URL': supabaseUrl,
      'SUPABASE_PUBLISHABLE_KEY': supabaseChavePublica,
      'CONTATO_ANUNCIE': contatoAnuncie,
      'CONTATO_SUGESTAO': contatoSugestao,
    }.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();
