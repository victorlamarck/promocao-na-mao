import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/tema.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('as cores do app geram temas diferentes entre si (o grafite virava verde-água)', () {
    for (final brilho in Brightness.values) {
      final primarias = [for (final (cor, _) in coresDoApp) temaApp(cor, brilho).colorScheme.primary];
      for (var i = 0; i < primarias.length; i++) {
        for (var j = i + 1; j < primarias.length; j++) {
          final (a, b) = (HSLColor.fromColor(primarias[i]), HSLColor.fromColor(primarias[j]));
          final matiz = ((a.hue - b.hue).abs() % 360).clamp(0, 180);
          final distantes = matiz.abs() > 30 || (a.saturation - b.saturation).abs() > 0.25;
          expect(distantes, isTrue, reason: '${coresDoApp[i].$2} × ${coresDoApp[j].$2} (${brilho.name}) ficam parecidas');
        }
      }
    }
  });

  test('tema escolhido é lembrado no aparelho; sem escolha, segue o do aparelho', () async {
    SharedPreferences.setMockInitialValues({});
    await carregarAparencia();
    expect(temaDoApp.value, ThemeMode.system);

    await escolherTemaDoApp(ThemeMode.dark);
    temaDoApp.value = ThemeMode.system; // como se o app fechasse
    await carregarAparencia();
    expect(temaDoApp.value, ThemeMode.dark);

    SharedPreferences.setMockInitialValues({'tema_do_app': 'valor-antigo'});
    temaDoApp.value = ThemeMode.system;
    await carregarAparencia();
    expect(temaDoApp.value, ThemeMode.system, reason: 'valor desconhecido não quebra');
  });
}
