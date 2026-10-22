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
        unidadeReferencia = j['unidade_referencia'] as String?,
        precoComparado = _num(j['preco_comparado']),
        unidadeComparada = j['unidade_comparada'] as String?;

  final int id;
  final String textoOriginal;
  final double? preco, precoDe, precoClube, precoReferencia;
  final String precoPor;
  final String? condicao, restricaoTipo, secao, unidadeReferencia;

  /// Só nas ofertas de comparar_oferta: R$/kg, l ou un do item que casou (numa oferta "A ou B" o
  /// precoReferencia é nulo, mas o item comparado tem preço por unidade).
  final double? precoComparado;
  final String? unidadeComparada;

  /// R$/kg, l ou un para mostrar e comparar: o do item comparado, senão o da oferta.
  double? get porUnidadeValor => precoComparado ?? precoReferencia;
  String? get porUnidadeTipo => unidadeComparada ?? unidadeReferencia;
  final List<int> restricaoLojas;
  final DateTime validadeFim;
  final int redeId;
  final String redeNome, redeSlug;
  final List<Map<String, dynamic>> itens;

  /// Código do produto do catálogo (migration 20), para o aviso "produto em oferta"; nulo se a oferta não tem
  /// produto ou se as alternativas ("A ou B") são produtos diferentes.
  String? get produtoCodigo {
    final codigos = itens.map((i) => i['produto_codigo'] as String?).toSet();
    return codigos.length == 1 ? codigos.first : null;
  }

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

/// Ids das ofertas com o menor R$/kg, R$/l ou R$/un entre as que têm a mesma unidade (selo "Mais barato").
/// Só conta unidade com 2 ofertas ou mais: sozinha não é "mais barata" que nada.
Set<int> maisBaratas(List<Oferta> ofertas) {
  final porTipo = <String, List<Oferta>>{};
  for (final o in ofertas) {
    if (o.porUnidadeValor != null && o.porUnidadeTipo != null) (porTipo[o.porUnidadeTipo!] ??= []).add(o);
  }
  return {
    for (final grupo in porTipo.values.where((g) => g.length > 1))
      for (final o in grupo)
        if (o.porUnidadeValor == grupo.map((o) => o.porUnidadeValor!).reduce((a, b) => a < b ? a : b)) o.id,
  };
}

/// Resposta de comparar_oferta: o mesmo produto em outros encartes e os parecidos (outra marca ou tamanho).
class Comparacao {
  Comparacao.fromJson(Map<String, dynamic> j)
      : mesmo = (j['mesmo'] as List).map((o) => Oferta.fromJson(o as Map<String, dynamic>)).toList(),
        similares = (j['similares'] as List).map((o) => Oferta.fromJson(o as Map<String, dynamic>)).toList();

  const Comparacao.vazia()
      : mesmo = const [],
        similares = const [];

  final List<Oferta> mesmo, similares;
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
