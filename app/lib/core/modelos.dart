// Modelos das views da API (docs/banco.md, "API para o app"). fromJson à mão.
// Dinheiro chega como número do Postgres (numeric); no app só é exibido, nunca somado.

double? _num(Object? v) => (v as num?)?.toDouble();

class Oferta {
  Oferta.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        textoOriginal = j['texto_original'] as String,
        preco = _num(j['preco']),
        precoDe = _num(j['preco_de']),
        precoClube = _num(j['preco_clube']),
        precoPor = j['preco_por'] as String,
        condicao = j['condicao'] as String?,
        restricaoTipo = j['restricao_tipo'] as String?,
        restricaoLojas = (j['restricao_lojas'] as List?)?.cast<int>() ?? const [],
        secao = j['secao'] as String?,
        validadeFim = DateTime.parse(j['validade_fim'] as String),
        redeId = j['rede_id'] as int,
        redeNome = j['rede_nome'] as String,
        redeSlug = j['rede_slug'] as String,
        itens = (j['itens'] as List).cast<Map<String, dynamic>>(),
        precoReferencia = _num(j['preco_referencia']),
        unidadeReferencia = j['unidade_referencia'] as String?;

  final int id;
  final String textoOriginal;
  final double? preco, precoDe, precoClube, precoReferencia;
  final String precoPor;
  final String? condicao, restricaoTipo, secao, unidadeReferencia;
  final List<int> restricaoLojas;
  final DateTime validadeFim;
  final int redeId;
  final String redeNome, redeSlug;
  final List<Map<String, dynamic>> itens;

  /// Nome para o card, montado dos itens (o texto do encarte às vezes traz preço e regras):
  /// "Macarrão Espaguete ou Macarrão Cortado Don Sapore". Sem itens, o texto do encarte.
  String get nome {
    if (itens.isEmpty) return textoOriginal;
    String junta(List<Object?> partes) => partes.whereType<String>().join(' ');
    final marcas = itens.map((i) => i['marca']).toSet();
    if (marcas.length == 1) return junta([itens.map((i) => i['nome']).whereType<String>().toSet().join(' ou '), marcas.first]);
    return itens.map((i) => junta([i['nome'], i['marca']])).toSet().join(' ou ');
  }
}

class Rede {
  Rede.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        nome = j['nome'] as String,
        slug = j['slug'] as String,
        ofertas = j['ofertas'] as int,
        lojas = j['lojas'] as int,
        ate = DateTime.parse(j['ate'] as String),
        // pode faltar no cache salvo por uma versão anterior
        atualizadoEm = j['atualizado_em'] == null ? null : DateTime.parse(j['atualizado_em'] as String).toLocal();

  final int id, ofertas, lojas;
  final String nome, slug;
  final DateTime ate;
  final DateTime? atualizadoEm;
}

class Anuncio {
  Anuncio.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        formato = j['formato'] as String,
        titulo = j['titulo'] as String,
        texto = j['texto'] as String?,
        imagemUrl = j['imagem_url'] as String?,
        linkUrl = j['link_url'] as String?,
        redeId = j['rede_id'] as int?;

  final int id;
  final String formato, titulo;
  final String? texto, imagemUrl, linkUrl;
  final int? redeId;
}
