import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/tema.dart';
import '../../core/widgets.dart';
import 'avisos.dart';

final _db = Supabase.instance.client;

/// Produto do catálogo com aviso ligado (tabela `produto`, leitura pública). Nome para a tela:
/// "Café Pilão 500g".
class ProdutoAvisado {
  ProdutoAvisado.fromJson(Map<String, dynamic> j)
      : codigo = j['codigo'] as String,
        busca = [j['nome'], j['marca']].whereType<String>().join(' '),
        nome = [
          j['nome'],
          j['marca'],
          if (j['quantidade'] != null) '${_numero(j['quantidade'] as num)}${j['unidade'] ?? ''}',
        ].whereType<String>().join(' ');

  ProdutoAvisado.semCatalogo(this.codigo)
      : nome = 'Produto que saiu do catálogo',
        busca = null;

  final String codigo, nome;

  /// Termo da busca ao tocar: sem o tamanho ("500g" no texto do encarte pode vir "500 g").
  final String? busca;

  static String _numero(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString().replaceAll('.', ',');
}

/// "Meus avisos": os mercados e produtos com sino ligado neste aparelho. Desligar é pelo sino de cada linha; a linha
/// fica na tela até sair dela, para dar para religar se tocou sem querer.
class MeusAvisosPage extends StatefulWidget {
  const MeusAvisosPage({super.key});

  @override
  State<MeusAvisosPage> createState() => _MeusAvisosPageState();
}

class _MeusAvisosPageState extends State<MeusAvisosPage> {
  // Os ligados na abertura da tela (ver o comentário da classe).
  final _produtos = avisoProduto.ligados.value.toList();
  final _mercados = avisoMercado.ligados.value.toList();
  late var _carga = _carregar();

  Future<(List<ProdutoAvisado>, Map<String, String>)> _carregar() async {
    final produtos = _produtos.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db.from('produto').select('codigo, nome, marca, quantidade, unidade').inFilter('codigo', _produtos);
    final redes = _mercados.isEmpty ? <Map<String, dynamic>>[] : await _db.from('rede').select('slug, nome').inFilter('slug', _mercados);
    final porCodigo = {for (final p in produtos) p['codigo'] as String: ProdutoAvisado.fromJson(p)};
    final lista = [for (final c in _produtos) porCodigo[c] ?? ProdutoAvisado.semCatalogo(c)]..sort((a, b) => a.nome.compareTo(b.nome));
    return (lista, {for (final r in redes) r['slug'] as String: r['nome'] as String});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Scaffold(
      appBar: AppBar(title: const Text('Meus avisos')),
      body: _produtos.isEmpty && _mercados.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 12, children: [
                Icon(Icons.notifications_none, size: 48, color: c.onSurfaceVariant),
                Text('Nenhum aviso ligado ainda.', style: fredoka(20)),
                const Text(
                    'Toque no sino de uma oferta (ou de um item da lista) para saber quando o produto entrar em oferta, '
                    'ou no sino de um mercado para saber quando sair encarte novo.',
                    textAlign: TextAlign.center),
              ]),
            )
          : FutureBuilder(
              future: _carga,
              builder: (context, s) {
                if (s.hasError) return Erro(onTentar: () => setState(() => _carga = _carregar()), texto: 'Não conseguimos carregar seus avisos.');
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final (produtos, nomes) = s.data!;
                return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
                  if (produtos.isNotEmpty) ...[
                    _Titulo('Produtos', 'Avisamos quando entrarem em oferta em qualquer mercado.'),
                    for (final p in produtos)
                      ListTile(
                        leading: const Icon(Icons.shopping_basket_outlined),
                        title: Text(p.nome),
                        onTap: p.busca == null ? null : () => context.go('/buscar?q=${Uri.encodeQueryComponent(p.busca!)}'),
                        trailing: BotaoAviso.produto(codigo: p.codigo, nome: p.nome),
                      ),
                  ],
                  if (_mercados.isNotEmpty) ...[
                    _Titulo('Mercados', 'Avisamos quando sair encarte novo.'),
                    for (final slug in _mercados)
                      ListTile(
                        leading: AvatarMercado(slug, tamanho: 36),
                        title: Text(nomes[slug] ?? slug),
                        onTap: () => context.push('/mercado/$slug'),
                        trailing: BotaoAviso.mercado(slug: slug, nome: nomes[slug] ?? slug),
                      ),
                  ],
                ]);
              },
            ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.titulo, this.sub);
  final String titulo, sub;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: fredoka(18)),
          Text(sub, style: TextStyle(fontSize: 13, color: context.cores.onSurfaceVariant)),
        ]),
      );
}
