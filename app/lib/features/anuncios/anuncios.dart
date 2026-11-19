import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/modelos.dart';

/// Regra do protótipo: no máximo 1 anúncio a cada 8 ofertas.
const ofertasPorAnuncio = 8;

/// Link de um anúncio vendido (vem do banco): só https abre; tel:, intent:, javascript: etc. viram null.
Uri? linkDoAnuncio(String? link) {
  final uri = Uri.tryParse(link ?? '');
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty ? uri : null;
}

/// Um espaço de anúncio na lista. [anuncio] null = nenhum vendido → AdSense ou "Anuncie aqui".
class EspacoAnuncio {
  const EspacoAnuncio(this.anuncio);
  final Anuncio? anuncio;
}

/// Ofertas com um [EspacoAnuncio] depois de cada [ofertasPorAnuncio], revezando os vendidos.
List<Object> intercalar(List<Oferta> ofertas, List<Anuncio> vendidos) {
  final lista = <Object>[];
  var n = 0;
  for (var i = 0; i < ofertas.length; i++) {
    lista.add(ofertas[i]);
    if ((i + 1) % ofertasPorAnuncio == 0) {
      lista.add(EspacoAnuncio(vendidos.isEmpty ? null : vendidos[n++ % vendidos.length]));
    }
  }
  return lista;
}

final _db = Supabase.instance.client;

Future<List<Anuncio>> anunciosDoFormato(String formato) async =>
    (await _db.from('anuncio_vigente').select().eq('formato', formato).order('id')).map(Anuncio.fromJson).toList();

Future<List<Anuncio>> anunciosDaBusca(String termo) async =>
    (await _db.rpc('anuncios_da_busca', params: {'termo': termo})).map<Anuncio>((j) => Anuncio.fromJson(j)).toList();
