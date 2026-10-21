import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sem internet devolve a última resposta salva; sem nada salvo, o erro', () async {
    SharedPreferences.setMockInitialValues({});
    Future<List<Map<String, dynamic>>> semInternet() async => throw Exception('offline');

    await expectLater(comCache('inicio', semInternet), throwsException);
    expect(await comCache('inicio', () async => [{'id': 1, 'nome': 'Café'}]), [{'id': 1, 'nome': 'Café'}]);
    expect(await comCache('inicio', semInternet), [{'id': 1, 'nome': 'Café'}]);
  });

  test('sinal ruim: depois de 5 s usa o salvo', () {
    fakeAsync((f) {
      SharedPreferences.setMockInitialValues({'cache_inicio': '[{"id":1}]'});
      List<Map<String, dynamic>>? r;
      comCache('inicio', () => Completer<List<Map<String, dynamic>>>().future).then((v) => r = v);
      f.elapse(const Duration(seconds: 6));
      expect(r, [{'id': 1}]);
    });
  });
}
