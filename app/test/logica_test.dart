import 'package:flutter_test/flutter_test.dart';
import 'package:promocao_na_mao/core/formato.dart';
import 'package:promocao_na_mao/core/localizacao.dart';
import 'package:promocao_na_mao/core/modelos.dart';
import 'package:promocao_na_mao/core/paginador.dart';
import 'package:promocao_na_mao/features/anuncios/anuncios.dart';

Oferta oferta(int id) => Oferta.fromJson({
      'id': id, 'texto_original': 'Item $id', 'preco': 4.99, 'preco_por': 'embalagem',
      'validade_fim': '2026-11-03', 'rede_id': 4, 'rede_nome': 'Big Mais', 'rede_slug': 'big-mais',
      'itens': [{'nome': 'Isotônico', 'marca': 'Powerade', 'quantidade': 500, 'unidade': 'ml'}],
    });

Anuncio anuncio(int id) => Anuncio.fromJson({'id': id, 'formato': 'feed', 'titulo': 'A$id'});

void main() {
  test('reais', () {
    expect(reais(4.99), 'R\$ 4,99');
    expect(reais(29), 'R\$ 29,00');
    expect(reais(1234.5), 'R\$ 1.234,50');
  });

  test('quando os dados foram atualizados', () {
    final quando = DateTime(2026, 10, 19, 8, 5);
    expect(atualizado(quando, DateTime(2026, 10, 19, 23, 59)), 'Atualizado hoje às 08:05');
    expect(atualizado(quando, DateTime(2026, 10, 20, 0, 1)), 'Atualizado ontem às 08:05');
    expect(atualizado(quando, DateTime(2026, 10, 22)), 'Atualizado em 19/10 às 08:05');
  });

  test('validade em português simples', () {
    final fim = DateTime(2026, 11, 3); // terça
    expect(valeAte(fim), 'Vale até terça, 03/11');
    expect(faltam(fim, DateTime(2026, 10, 18, 23, 59)), 'Faltam 16 dias');
    expect(faltam(fim, DateTime(2026, 11, 2)), 'Falta 1 dia');
    expect(faltam(fim, DateTime(2026, 11, 3, 8)), 'Vence hoje');
    expect(avisoValidade(fim, DateTime(2026, 11, 3, 23)), 'Vence hoje');
    expect(avisoValidade(fim, DateTime(2026, 11, 2)), 'Vence amanhã');
    expect(avisoValidade(fim, DateTime(2026, 11, 4)), 'Encarte venceu');
    expect(avisoValidade(fim, DateTime(2026, 10, 31)), isNull);
    expect(porUnidade(4.76, 'kg'), 'R\$ 4,76 o kg');
    expect(porUnidade(null, 'kg'), isNull);
    expect(porUnidade(1.99, 'l'), 'R\$ 1,99 o litro');
    expect(porUnidade(12.99, 'kg', preco: 12.99), isNull); // repetiria o preço
    expect(porUnidade(3.5, 'un'), isNull); // "cada" não diz nada a mais
  });

  test('nome do card: montado dos itens, sem o preço do texto do encarte', () {
    expect(oferta(1).nome, 'Isotônico Powerade');
    Oferta com(List<Map<String, dynamic>> itens) => Oferta.fromJson({
          'id': 1, 'texto_original': 'Mac Espag ou Cortado Don Sapore 400g R\$ 1,99', 'preco_por': 'embalagem',
          'validade_fim': '2026-11-03', 'rede_id': 4, 'rede_nome': 'Mart Minas', 'rede_slug': 'mart-minas', 'itens': itens,
        });
    expect(com([{'nome': 'Macarrão Espaguete', 'marca': 'Don Sapore'}, {'nome': 'Macarrão Cortado', 'marca': 'Don Sapore'}]).nome,
        'Macarrão Espaguete ou Macarrão Cortado Don Sapore');
    expect(com([{'nome': 'Cerveja Pilsen', 'marca': 'Brahma'}, {'nome': 'Cerveja Pilsen', 'marca': 'Skol'}]).nome,
        'Cerveja Pilsen Brahma ou Cerveja Pilsen Skol');
    expect(com([{'nome': 'Leite', 'marca': null}, {'nome': 'Leite', 'marca': null}]).nome, 'Leite');
    expect(com([]).nome, 'Mac Espag ou Cortado Don Sapore 400g R\$ 1,99');

    // aviso de produto: só quando a oferta é de um produto só do catálogo
    expect(com([{'nome': 'Café', 'produto_codigo': 'cafe-pilao-500g'}]).produtoCodigo, 'cafe-pilao-500g');
    expect(com([{'nome': 'Café', 'produto_codigo': 'cafe-pilao-500g'}, {'nome': 'Café', 'produto_codigo': 'cafe-pilao-500g'}]).produtoCodigo,
        'cafe-pilao-500g');
    expect(com([{'nome': 'Café', 'produto_codigo': 'cafe-pilao-500g'}, {'nome': 'Café', 'produto_codigo': 'cafe-melitta-500g'}]).produtoCodigo,
        isNull);
    expect(com([{'nome': 'Café', 'produto_codigo': null}]).produtoCodigo, isNull);

    // atacado: selo "Preço de atacado" e, no card, a condição sem o que o selo já diz
    Oferta cond(String? condicao) => Oferta.fromJson({
          'id': 1, 'texto_original': 'Café', 'preco_por': 'embalagem', 'condicao': condicao,
          'validade_fim': '2026-11-03', 'rede_id': 4, 'rede_nome': 'Mart Minas', 'rede_slug': 'mart-minas', 'itens': [],
        });
    const atac = 'preço de atacado: vale na compra em quantidade (mesma fragrância/sabor)';
    expect(cond(atac).atacado, isTrue);
    expect(cond(atac).condicaoCurta, isNull);
    expect(cond('$atac; leve 12 pague 11').condicaoCurta, 'leve 12 pague 11');
    expect(cond('leve 12 pague 11').atacado, isFalse);
    expect(cond('leve 12 pague 11').condicaoCurta, 'leve 12 pague 11');
    expect(cond(null).atacado, isFalse);
    expect(com([]).produtoCodigo, isNull);
  });

  test('1 anúncio a cada 8 ofertas, revezando os vendidos', () {
    final ofertas = List.generate(20, oferta);
    final lista = intercalar(ofertas, [anuncio(1), anuncio(2)]);
    final espacos = lista.whereType<EspacoAnuncio>().toList();
    expect(espacos.length, 2);
    expect(lista[8], isA<EspacoAnuncio>());
    expect(espacos.map((e) => e.anuncio!.id), [1, 2]);
    expect(intercalar(ofertas.sublist(0, 7), [anuncio(1)]).whereType<EspacoAnuncio>(), isEmpty);
    expect(intercalar(ofertas, []).whereType<EspacoAnuncio>().first.anuncio, isNull); // → AdSense / "Anuncie aqui"
  });

  test('link de anúncio: só https abre', () {
    expect(linkDoAnuncio('https://bigmais.com.br/oferta')?.host, 'bigmais.com.br');
    for (final ruim in ['tel:33999999999', 'intent://x#Intent;end', 'javascript:alert(1)', 'http://x.com', 'https:', 'nada', '', null]) {
      expect(linkDoAnuncio(ruim), isNull, reason: '$ruim');
    }
  });

  test('paginador: páginas seguidas, fim e resposta antiga descartada', () async {
    final dados = List.generate(30, (i) => i);
    final p = Paginador<int>((de, ate) async => dados.sublist(de, (ate + 1).clamp(0, dados.length)), porPagina: 24);
    await p.proxima(() {});
    expect(p.itens.length, 24);
    expect(p.fim, isFalse);
    await p.proxima(() {});
    expect(p.itens, dados);
    expect(p.fim, isTrue);

    final lenta = Paginador<int>((de, ate) => Future.delayed(const Duration(milliseconds: 20), () => [99]));
    final antiga = lenta.proxima(() {});
    lenta.reiniciar();
    await antiga;
    expect(lenta.itens, isEmpty);
  });

  test('distância entre lojas de GV', () {
    // Atacadão (Travessa Rio Bahia) → Big Mais Vila Isa: ~2 km em linha reta
    final d = distanciaKm(-18.87923, -41.95878, -18.89751, -41.948715);
    expect(d, closeTo(2.27, 0.05));
    expect(textoDistancia(0.8), '800 m');
    expect(textoDistancia(1.44), '1,4 km');
  });

  Oferta comUnidade(int id, double? valor, String? tipo, {bool comparada = false}) => Oferta.fromJson({
        ...{'id': id, 'texto_original': 'Item $id', 'preco': 4.99, 'preco_por': 'embalagem', 'validade_fim': '2026-11-03',
            'rede_id': 4, 'rede_nome': 'Big Mais', 'rede_slug': 'big-mais', 'itens': []},
        if (comparada) ...{'preco_comparado': valor, 'unidade_comparada': tipo}
        else ...{'preco_referencia': valor, 'unidade_referencia': tipo},
      });

  test('selo "mais barato": menor R\$ por unidade entre as da mesma unidade', () {
    final ofertas = [
      comUnidade(1, 9.90, 'l'),
      comUnidade(2, 7.14, 'l'), // mais barata por litro
      comUnidade(3, 4.00, 'kg'), // única por kg: não ganha selo
      comUnidade(4, null, null), // "A ou B" sem preço por unidade
      comUnidade(5, 7.14, 'l', comparada: true), // empate: as duas ganham
    ];
    expect(maisBaratas(ofertas), {2, 5});
    expect(maisBaratas([]), isEmpty);
  });

  test('comparação: preço do item comparado vale mais que o da oferta', () {
    final c = Comparacao.fromJson({
      'mesmo': [],
      'similares': [
        {'id': 9, 'texto_original': 'Iate ou Coroa 2L', 'preco': 3.99, 'preco_por': 'embalagem', 'validade_fim': '2026-10-25',
         'rede_id': 1, 'rede_nome': 'Coelho Diniz', 'rede_slug': 'coelho-diniz', 'itens': [],
         'preco_referencia': null, 'unidade_referencia': null, 'preco_comparado': 1.995, 'unidade_comparada': 'l'},
      ],
    });
    expect(c.mesmo, isEmpty);
    expect((c.similares.single.porUnidadeValor, c.similares.single.porUnidadeTipo), (1.995, 'l'));
    expect(oferta(1).porUnidadeValor, isNull);
  });
}
