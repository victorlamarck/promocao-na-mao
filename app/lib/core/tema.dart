import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identidade "Vizinho amigo" (docs/design.md): a cor do app é escolha de quem usa;
/// a marca fica no símbolo, na tipografia (Fredoka + Nunito) e no jeito de falar.
const coresDoApp = [
  (Color(0xFF1E7A66), 'verde-água'),
  (Color(0xFF5B4BC4), 'roxo'),
  (Color(0xFF2F5D8C), 'azul-petróleo'),
  (Color(0xFFA8326E), 'framboesa'),
  (Color(0xFF3F4A44), 'grafite'),
];

/// Cor escolhida, lembrada no aparelho. O MaterialApp escuta e troca o tema na hora.
final corDoApp = ValueNotifier<Color>(coresDoApp.first.$1);

Future<void> carregarCorDoApp() async {
  final valor = (await SharedPreferences.getInstance()).getInt('cor_do_app');
  if (valor != null) corDoApp.value = Color(valor);
}

Future<void> escolherCorDoApp(Color cor) async {
  corDoApp.value = cor;
  await (await SharedPreferences.getInstance()).setInt('cor_do_app', cor.toARGB32());
}

/// Identidade de cada mercado no app: cor, sigla e nome do programa de clube.
/// Sem logotipos (marca das redes). Mercado novo sem entrada aqui fica cinza.
class Mercado {
  const Mercado(this.cor, this.sigla, [this.clube]);
  final Color cor;
  final String sigla;
  final String? clube;

  static const _porSlug = {
    'big-mais': Mercado(Color(0xFF1D4ED8), 'BM', 'bigmais+'),
    'coelho-diniz': Mercado(Color(0xFFB45309), 'CD'),
    'atacadao': Mercado(Color(0xFF0F766E), 'AT', 'app Meu Atacadão'),
    'supermercados-bh': Mercado(Color(0xFF6D28D9), 'BH', 'Meu BH'),
    'mart-minas': Mercado(Color(0xFFBE123C), 'MM', 'Mart Mais'),
  };

  static Mercado de(String? slug) =>
      _porSlug[slug] ?? Mercado(const Color(0xFF707971), slug == null ? '?' : slug.substring(0, 2).toUpperCase());
}

/// Fredoka 600: títulos e preços.
TextStyle fredoka(double tamanho, {Color? cor}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: tamanho, fontWeight: FontWeight.w600, color: cor, height: 1.2);

/// Atalhos para os papéis de cor do Material 3 usados no protótipo.
extension CoresDoTema on BuildContext {
  ColorScheme get cores => Theme.of(this).colorScheme;

  /// Preço: o elemento mais forte do card (tom escuro da cor do app; claro no tema escuro).
  Color get corPreco => cores.onPrimaryContainer;
}

ThemeData temaApp(Color semente, Brightness brilho) {
  final esquema = ColorScheme.fromSeed(seedColor: semente, brightness: brilho);
  // Fontes embutidas (assets/fontes, pubspec.yaml): abrem iguais sem internet.
  final base = ThemeData(colorScheme: esquema, useMaterial3: true, fontFamily: 'Nunito');
  final arredondado = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    scaffoldBackgroundColor: esquema.surfaceContainerLow,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: fredoka(22, cor: esquema.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: esquema.surfaceContainerLowest,
      shape: arredondado.copyWith(side: BorderSide(color: esquema.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(44, 44), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
