# Ficha da App Store — Promoção na Mão

Texto pronto para colar no App Store Connect (app `br.com.promocaonamao.app`, Apple ID 6831775636).
Feito em 08/11/2026 a partir da [ficha da Play](../ficha.md), adaptado aos campos e limites da Apple.
Contagens com Python (caracteres Unicode). Se o app mudar, revise junto com a ficha da Play.

## App Information (vale para todas as versões)

| Campo | Valor | Limite |
|---|---|---|
| Name | `Promoção na Mão` | 15/30 |
| Subtitle | `Ofertas dos mercados de GV` | 26/30 |
| Primary Category | **Shopping** | |
| Secondary Category | **Food & Drink** (opcional) | |
| Content Rights | "Contains third-party content": **Yes** (nomes, logos e preços dos encartes dos mercados) → confirmar que pode usar. **[dev decide]** | |
| Age Rating | ver abaixo | |

## Pricing and Availability

- Price: **Free** (0).
- Availability: **Brasil** só (o app é de Governador Valadares; outros países só aumentam a revisão sem trazer usuário).

## Versão 1.0 (na prática a 0.7.2) — Product Page

**Promotional Text** (pode mudar a qualquer hora sem nova revisão; 153/170):
```
Ofertas de hoje do Atacadão, Big Mais, Coelho Diniz, Mart Minas e Supermercados BH num lugar só. Busque o produto e monte sua lista separada por mercado.
```

**Keywords** (separadas por vírgula, sem espaço depois da vírgula; não repetir palavras do nome/subtítulo; 100/100):
```
encarte,promocao,supermercado,folheto,lista de compras,preço,desconto,governador valadares,valadares
```

**Support URL:** `https://www.promocaonamao.com.br/privacidade` (tem o e-mail de contato).
**Marketing URL:** `https://www.promocaonamao.com.br`
**Copyright:** `2026 VL Desenvolvimento e Tecnologia LTDA`

**Description** (2886/4000):
<!-- início da descrição -->
```
Vai fazer compras em Governador Valadares? O Promoção na Mão junta as ofertas dos encartes dos supermercados da cidade num lugar só, para você achar o que precisa sem folhear um folheto de cada vez.

MERCADOS QUE JÁ ESTÃO NO APP
• Atacadão
• Big Mais
• Coelho Diniz
• Mart Minas
• Supermercados BH
Outras redes da cidade vão entrar aos poucos. Sentiu falta de algum mercado? Toque em "Sugerir mercado" e conte pra gente.

BUSQUE PELO PRODUTO
Digite "arroz", "café" ou "sabão em pó" e veja as ofertas desse produto em todos os encartes de uma vez. Dá para filtrar por mercado e ordenar os resultados. O app mostra o preço, o preço antigo, o preço por quilo ou por unidade e o preço de clube quando o mercado tem (por exemplo, "com bigmais+", "com Mart Mais" ou "com app Meu Atacadão").

OFERTAS DE HOJE, COM VALIDADE
Mostramos só as ofertas que valem hoje. Cada oferta diz até quando vale e em quais lojas, e o app avisa quando ela vence hoje ou amanhã. Os encartes são conferidos e atualizados pela nossa equipe a cada novo folheto.

MONTE SUA LISTA DE COMPRAS
Toque em "Adicionar" nas ofertas que interessam. A lista já fica separada por mercado, com a quantidade e o total de cada um. Também dá para anotar itens à mão, como "pão francês", mesmo sem oferta.

AVISO DE OFERTAS NOVAS
Toque no sino na página de um mercado e o app avisa quando sair encarte novo dele. Toque no aviso e veja as ofertas. Você escolhe os mercados e desliga quando quiser.

COMPARTILHE A LISTA POR LINK
Mande a lista pelo WhatsApp para quem vai ao mercado. Quem recebe abre o link no celular, sem instalar nada e sem criar conta, e marca o que já pegou. Você vê na hora o que já foi para o carrinho.

MERCADOS PERTO DE VOCÊ
Se você permitir, o app usa a sua localização para mostrar os mercados do mais perto ao mais longe. A distância é calculada no próprio celular: a sua localização não é enviada para nós. Se preferir não permitir, os mercados aparecem em ordem alfabética.

SEM CADASTRO
Não precisa criar conta, nem informar e-mail ou telefone. A sua lista fica ligada a um código guardado no seu celular. Quando quiser, apague a lista inteira.

DO SEU JEITO
Escolha a cor do app e use no tema claro ou escuro.

FUNCIONA COM SINAL FRACO
A sua lista, a lista que você recebeu e as ofertas que você já abriu ficam salvas no celular. Se a internet cair no meio do mercado, você continua vendo a última versão.

ANÚNCIOS
O app é gratuito e se mantém com anúncios do comércio local e do Google, sempre marcados com o selo "Anúncio" ou "Patrocinado". Eles nunca aparecem na sua lista de compras.

IMPORTANTE
Os preços e as condições são os dos encartes dos próprios mercados, que valem enquanto durarem os estoques e podem ter regras de cada loja. Na dúvida, confira no mercado. O Promoção na Mão não é ligado a nenhuma das redes.

Dúvidas, sugestões ou quer anunciar? Escreva para oi.promocaonamao@gmail.com.
```
<!-- fim da descrição -->

**Screenshots** — a tela atual do App Store Connect pede **"iPhone with Dynamic Island (medium display)"**, 6,1"/6,3":
**1206×2622** (ou 1179×2556), RGB sem transparência → [capturas-6.3/](capturas-6.3/). As de 6,9" (1320×2868, [capturas/](capturas/))
foram recusadas nessa área em 08/11/2026 ("File dimensions are invalid"); `tools/reduzir.mjs` faz uma a partir da outra.
Ordem:
`1-inicio`, `2-busca`, `3-lista`, `4-oferta`, `5-mercados`. A Apple reduz sozinha para os iPhones menores.
iPad: não precisa (o app é só iPhone).

Como foram feitas: o próprio app (Flutter web, `config/prod.json`, dados reais de prod de 08/11/2026) num Chrome
sem janela em 390×844 ×3, localização negada, e a moldura com legenda em Fredoka no estilo das capturas da Play.
Scripts em [tools/](tools/) (`npm i playwright-core` numa pasta temporária; usa o Chrome instalado):
`node fotos.mjs <app/build/web> <cru> roteiro.json` e `node moldura.mjs <cru> <saida>`.
Atenção: o roteiro cria uma lista de verdade no banco de prod (some sozinha em 6 meses; rodar com cuidado).

**Header e Search Results** (aba "Header and Search Results", opcionais, só aparecem no iOS 27+; sem transparência):
[destaques/](destaques/) — `header-3840x1646.png` (21:9, sem texto: a Apple sobrepõe nome e ícone) e
`busca-3840x2560.png` (3:2, legenda "As ofertas de GV numa lista só"). Geradas por `tools/destaques.mjs` a partir das
telas cruas. Medidas: [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/).

## App Review Information

| Campo | Valor |
|---|---|
| Sign-in required | **Não** (desmarcar; o app não tem login) |
| Contact | nome, telefone e e-mail do dev |
| Notes | texto abaixo |

```
O app reúne as ofertas dos encartes dos supermercados de Governador Valadares (MG, Brasil). Não tem login nem cadastro: todas as funções estão disponíveis ao abrir.
- Busca: aba Buscar, digite "arroz" ou "café".
- Lista de compras: toque em "Adicionar" numa oferta; a aba Lista mostra os itens separados por mercado e o botão Compartilhar gera um link.
- Avisos (push): abra um mercado na aba Mercados e toque no sino.
- Localização é opcional e só ordena os mercados por distância, calculada no aparelho.
- Os anúncios são do comércio local (vendidos por nós) e do Google AdMob, sem rastreamento (o app não pede ATT).
```

## Age Rating (questionário da Apple)

| Pergunta | Resposta | Por quê |
|---|---|---|
| Violência (cartoon, realista, prolongada), horror, temas maduros, conteúdo sexual/nudez, linguagem, medicina/tratamento | None | |
| Alcohol, Tobacco, or Drug Use or References | **Infrequent/Mild** | os encartes têm cerveja, vinho e às vezes cigarro à venda |
| Simulated Gambling, Contests, Gambling | None / No | |
| Unrestricted Web Access | No | os links abrem só o site do app e o WhatsApp |
| User-Generated Content | No | a lista compartilhada só vai para quem o dono manda o link; não é conteúdo público |
| Messaging and Chat | No | |
| Advertising | **Yes** | AdMob e anúncios locais |
| Parental Controls, Age Assurance | No | |

Resultado esperado: 12+/13+ (por causa do álcool). Se a Apple calcular outra faixa, vale a dela.

## App Privacy

Respostas do rótulo de privacidade: ver a tabela da conversa de 08/11/2026 (copiada em
[privacidade.md](privacidade.md)).
