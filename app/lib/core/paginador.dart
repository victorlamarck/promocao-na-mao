/// Lista paginada com setState: a página chama [proxima] e redesenha com [atualizar].
/// A API devolve no máximo 1.000 linhas; pedimos [porPagina] por vez com .range(de, ate).
class Paginador<T> {
  Paginador(this.buscar, {this.porPagina = 24});

  /// Busca as linhas [de]..[ate] (inclusive), na ordem estável da consulta.
  final Future<List<T>> Function(int de, int ate) buscar;
  final int porPagina;

  final itens = <T>[];
  bool carregando = false, erro = false, fim = false;
  var _geracao = 0;

  /// Recomeça do zero (ex.: novo termo de busca). Respostas da busca anterior são descartadas.
  void reiniciar() {
    _geracao++;
    itens.clear();
    carregando = erro = fim = false;
  }

  Future<void> proxima(void Function() atualizar) async {
    if (carregando || fim) return;
    final geracao = _geracao;
    carregando = true;
    erro = false;
    atualizar();
    try {
      final novos = await buscar(itens.length, itens.length + porPagina - 1);
      if (geracao != _geracao) return; // chegou a resposta de uma busca antiga
      itens.addAll(novos);
      fim = novos.length < porPagina;
    } catch (_) {
      if (geracao != _geracao) return;
      erro = true;
    }
    carregando = false;
    atualizar();
  }
}
