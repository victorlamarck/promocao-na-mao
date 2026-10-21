# Documentação — Promoção na Mão (app e site)

Ofertas dos supermercados de Governador Valadares-MG numa lista só. Resumo em [`CLAUDE.md`](../CLAUDE.md).

| Documento | Conteúdo |
|---|---|
| [site.md](site.md) | **Site** (Astro, www.promocaonamao.com.br): páginas geradas no build, lista, busca, esteira, domínio |
| [app.md](app.md) | **App Flutter** (celular): como rodar, configuração, estrutura, rotas, lista de compras, publicar |
| [design.md](design.md) | **Protótipo do app**: lista de compras compartilhada, telas, identidade, anúncios |
| [loja/](loja/README.md) | Material da Play Store: ficha, segurança dos dados, capturas |

Banco, coleta dos encartes e extração ficam no repositório privado `promocao-na-mao-dados`.

## Estrutura

```
CLAUDE.md            contexto resumido (lido pelo Claude a cada sessão)
docs/                esta documentação (design/prototipo/ = arquivos do protótipo)
app/                 app Flutter (celular)
site/                site em Astro (www.promocaonamao.com.br)
release.txt          "Novidades" da próxima versão na Play (≤300 caracteres)
versions.txt         histórico das versões do app
```
