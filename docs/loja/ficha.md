# Ficha da Google Play — Promoção na Mão

Texto pronto para colar no Play Console (*Crescimento → Presença na loja → Ficha principal da loja*).
Idioma: português (Brasil). Contagens feitas com `node` (caracteres Unicode, como o Play conta).
Escrito em 20/10/2026 e revisado em 21/10 (Mart Minas, avisos, sinal fraco). Se o app mudar (comparação de preços, AdMob),
revise a descrição, a classificação e o [seguranca-dos-dados.md](seguranca-dos-dados.md).

## Nome do app (máx. 30)

**Promoção na Mão** — 15 caracteres.

Alternativa, se quiser a cidade no nome para a busca da loja: `Promoção na Mão: ofertas de GV` (30, no limite).
Recomendo o nome curto: o Google desaconselha palavras-chave no título, e a cidade já está na descrição.

## Descrição curta (máx. 80)

```
Ofertas dos mercados de GV, busca por produto e lista de compras compartilhada
```

**78 caracteres.**

## Descrição completa (máx. 4000)

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
Digite "arroz", "café" ou "sabão em pó" e veja as ofertas desse produto em todos os encartes de uma vez. Dá para filtrar por mercado e ordenar os resultados. O app mostra o preço, o preço antigo ("Antes R$ 24,90"), o preço por quilo ou por unidade e o preço de clube quando o mercado tem (por exemplo, "com bigmais+", "com Mart Mais" ou "com app Meu Atacadão").

OFERTAS DE HOJE, COM VALIDADE
Mostramos só as ofertas que valem hoje. Cada oferta diz até quando vale ("Vale até terça, 03/11"), e o app avisa quando ela vence hoje ou amanhã. Os encartes são conferidos e atualizados pela nossa equipe a cada novo folheto.

MONTE SUA LISTA DE COMPRAS
Toque em "Adicionar" nas ofertas que interessam. A lista já fica separada por mercado, com a quantidade de cada item. Também dá para anotar itens à mão, como "pão francês", mesmo sem oferta.

AVISO DE OFERTAS NOVAS
Toque no sino na página de um mercado e o app avisa quando sair encarte novo dele. Toque no aviso e veja as ofertas. Você escolhe os mercados e desliga quando quiser.

COMPARTILHE A LISTA POR LINK
Mande a lista pelo WhatsApp para quem vai ao mercado. Quem recebe abre o link no celular, sem instalar nada e sem criar conta, e marca o que já pegou. Você vê na hora o que já foi para o carrinho. É sempre o mesmo link: se você mudar a lista, quem recebeu vê a versão nova. Você escolhe se a pessoa só vê a lista ou se também pode marcar os itens.

MERCADOS PERTO DE VOCÊ
Se você permitir, o app usa a sua localização aproximada para mostrar os mercados do mais perto ao mais longe. A distância é calculada no próprio celular: a sua localização não é enviada para nós. Se preferir não permitir, os mercados aparecem em ordem alfabética.

SEM CADASTRO
Não precisa criar conta, nem informar e-mail ou telefone. A sua lista fica ligada a um código guardado no seu celular. Quando quiser, apague a lista inteira no botão "Apagar minha lista".

DO SEU JEITO
Escolha a cor do app (verde-água, roxo, azul-petróleo, framboesa ou grafite) e use no tema claro ou escuro.

FUNCIONA COM SINAL FRACO
A sua lista, a lista que você recebeu e as ofertas que você já abriu no início e nos mercados ficam salvas no celular. Se a internet cair no meio do mercado, você continua vendo a última versão.

ANÚNCIOS
O app é gratuito e se mantém com anúncios do comércio local e do Google, sempre marcados com o selo "Anúncio" ou "Patrocinado". Eles nunca aparecem na sua lista de compras e não cobrem preço nem validade.

IMPORTANTE
Os preços e as condições são os dos encartes dos próprios mercados, que valem enquanto durarem os estoques e podem ter regras de cada loja. Na dúvida, confira no mercado. O Promoção na Mão não é ligado a nenhuma das redes.

Dúvidas, sugestões ou quer anunciar? Escreva para oi.promocaonamao@gmail.com.
```
<!-- fim da descrição -->

**3211 caracteres** (de 4000).

Antes de publicar, confira com o dev:
- "conferidos e atualizados pela nossa equipe a cada novo folheto" — hoje a coleta é manual pelo dev
  (`/coleta-diaria`); se algum dia passar uma rede sem atualizar, a frase continua verdadeira, mas não
  prometa "todo dia".
- "Funciona com sinal fraco" — vale para a lista e a primeira página do Início e de cada mercado (docs/app.md);
  busca e detalhe da oferta precisam de internet. O texto não promete a busca.
- "Aviso de ofertas novas" — só no Android por enquanto (iPhone precisa da chave APNs); a ficha é da Play.
- "anúncios do comércio local e do Google": o AdMob entrou em 21/10/2026 (formulário de segurança dos dados revisto).
- Evitados de propósito: "todos os mercados", "comparar preços"/"mais barato" (a comparação ainda não
  existe), "melhor", "nº 1", "grátis" em destaque, emojis e CAIXA ALTA fora dos subtítulos curtos.

## Categoria, tags e contato

| Campo | Valor |
|---|---|
| Tipo | App |
| Categoria | **Compras** (alternativa: Estilo de vida; Compras é o que o usuário espera) |
| Tags (até 5, escolhidas da lista fixa do Console) | as que existirem mais perto de: ofertas/cupons, lista de compras, supermercado/mercearia, compras locais. Não marcar "comparação de preços" (ainda não existe) |
| E-mail de contato | oi.promocaonamao@gmail.com |
| Site | https://www.promocaonamao.com.br |
| Telefone | deixar em branco (opcional) |
| Política de privacidade | https://www.promocaonamao.com.br/privacidade |

## Gráficos

| Item | Arquivo | Conferido |
|---|---|---|
| Ícone 512×512 (PNG 32 bits) | [icone-512.png](icone-512.png) | 512×512, RGBA |
| Imagem de destaque 1024×500 | [destaque-1024x500.png](destaque-1024x500.png) | 1024×500, RGB sem transparência |
| Capturas de celular (2 a 8) | [capturas/](capturas/) (cruas) ou [capturas-com-legenda/](capturas-com-legenda/) | 1080×1920 (9:16) |

Ordem sugerida das capturas com legenda: ofertas de hoje → busca → lista → lista recebida.
Se usar as cruas, sugestão: 2-ofertas-de-hoje, 4-busca, 3-mercado, 5-lista, 6-compartilhar, 7-lista-recebida.

## Classificação de conteúdo (questionário IARC)

*Política → Conteúdo do app → Classificação de conteúdo.* Categoria do questionário: **"Todos os outros tipos de app"**
(não é jogo, nem rede social, nem app de comunicação).

| Pergunta (resumo) | Resposta | Por quê |
|---|---|---|
| Violência, sangue, medo | Não | |
| Sexualidade, nudez | Não | Os encartes podem ter roupa íntima/fralda em foto de produto: isso não conta como nudez. |
| Linguagem imprópria | Não | |
| Drogas controladas | Não | |
| Álcool e tabaco | **Sim, referência** — confirme | Os encartes têm cerveja, vinho e destilados à venda (e às vezes cigarro). O IARC pergunta se o app "mostra ou faz referência" a álcool/tabaco; ofertas de bebida alcoólica são referência. Responder "Não" pode render reclassificação depois. Normalmente isso não sobe a faixa para além de 12 anos no Brasil (ClassInd), mas o resultado final é o que o IARC calcular. |
| Apostas/jogos de azar, simulados | Não | |
| Humor grosseiro | Não | |
| Os usuários podem interagir ou trocar conteúdo? | **Sim** (recomendado) | A lista de compras compartilhada leva texto livre digitado pela pessoa (itens "anotados à mão" e o nome opcional "Seu nome") para quem abrir o link, e quem recebe pode marcar itens que o dono vê na hora. É pouco — não tem chat, perfil público nem busca de pessoas, e o link só vai para quem o dono escolher —, mas é troca de conteúdo entre usuários. Responder "Sim" é o lado conservador; o efeito é só o aviso "Interação do usuário", sem subir a idade. |
| Compartilha a localização do usuário com outros usuários? | Não | A localização fica no aparelho (ver seguranca-dos-dados.md). |
| Compras digitais / no app | Não | Não há compras no app. |
| O app é um navegador da web ou mecanismo de busca? | Não | A busca é só dentro das ofertas do próprio app. |
| Contém anúncios | (é outra tela, abaixo; **Sim**) | |

## Público-alvo e conteúdo

*Política → Conteúdo do app → Público-alvo e conteúdo.*

- **Faixa etária do público-alvo: 18 anos ou mais** (marcar só "18+").
  - Por quê: quem usa é quem faz as compras da casa; a política de privacidade diz "feito para adultos".
    Marcar 13–17 também não muda nada no app, mas obriga a cumprir regras extras de anúncios para
    adolescentes (AdMob com conteúdo adequado, sem anúncio personalizado para menores) e põe o app sob a
    lupa da política de famílias. Com 18+ a ficha é mais simples e coerente com a política.
  - Nunca marcar faixas abaixo de 13: o app não é para crianças e entraria no programa Família.
- "O app pode atrair crianças sem querer?" **Não** (sem personagens, jogos ou linguagem infantil;
  o símbolo sorridente é discreto). Se o Google perguntar sobre o apelo visual, a resposta é a mesma.

## Anúncios

*Política → Conteúdo do app → Anúncios:* **Sim, o app contém anúncios.**
Hoje: anúncios vendidos direto pelo dev (tabela `anuncio`, cards "Anúncio"/"Patrocinado") e o espaço
"Anuncie aqui"; desde 21/10/2026, nos espaços sem anúncio vendido, anúncios do Google pelo **AdMob** (Android).

## Outras declarações da mesma tela (Conteúdo do app)

| Declaração | Resposta sugerida |
|---|---|
| Acesso ao app (o revisor precisa de login?) | "Todas as funcionalidades estão disponíveis sem restrição de acesso" — não há login. |
| App de notícias | Não |
| App de saúde | Não |
| App governamental | Não |
| Recursos financeiros | Nenhum ("Meu app não oferece recursos financeiros") |
| ID de publicidade (Android 13+) | Hoje **Não** — confirme no merged manifest do build que nenhuma biblioteca adicionou `com.google.android.gms.permission.AD_ID` (o `firebase_core` sozinho não adiciona). Quando entrar o AdMob, muda para **Sim, para publicidade**. |
| Segurança dos dados | ver [seguranca-dos-dados.md](seguranca-dos-dados.md) |
