import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Distância em linha reta (fórmula de haversine), em km.
double distanciaKm(double lat1, double lng1, double lat2, double lng2) {
  const raioTerra = 6371.0;
  double rad(double g) => g * pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = pow(sin(dLat / 2), 2) + cos(rad(lat1)) * cos(rad(lat2)) * pow(sin(dLng / 2), 2);
  return 2 * raioTerra * asin(sqrt(a));
}

/// "800 m" / "1,4 km".
String textoDistancia(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

Future<Map<int, double>>? _cache;

/// Distância da loja mais perto de cada rede (rede_id → km). Vazio se a pessoa negar a localização.
/// Pede a permissão uma vez por abertura do app. Com [pedir] false (Início) só usa se a pessoa já permitiu:
/// o pedido sem contexto aparecia por cima das boas-vindas, antes da 1ª oferta (t13); quem pede é a aba Mercados.
Future<Map<int, double>> distanciaPorRede({bool pedir = true}) async {
  if (!pedir && !await _permitida()) return {};
  return _cache ??= _calcular();
}

Future<bool> _permitida() async {
  try {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  } catch (_) {
    return false;
  }
}

Future<Map<int, double>> _calcular() async {
  try {
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) permissao = await Geolocator.requestPermission();
    if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) return {};
    final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.low));
    final lojas = await Supabase.instance.client.from('loja').select('rede_id, lat, lng').not('lat', 'is', null);
    final perto = <int, double>{};
    for (final l in lojas) {
      final d = distanciaKm(p.latitude, p.longitude, (l['lat'] as num).toDouble(), (l['lng'] as num).toDouble());
      final rede = l['rede_id'] as int;
      if (d < (perto[rede] ?? double.infinity)) perto[rede] = d;
    }
    return perto;
  } catch (_) {
    return {}; // sem GPS, navegador sem permissão etc. → ordem alfabética
  }
}
