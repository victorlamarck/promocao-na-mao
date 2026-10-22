# Design do app

Protótipo navegável: <https://claude.ai/artifact/DFKnGuRQRKDjSAzAuvc2bN> (privado; compartilhar
pelo menu Share). Cópia dos arquivos em [`design/prototipo/`](design/prototipo/), tirada em 19/10/2026 —
a versão viva é a do link.

Histórico: 18/10 primeira versão (busca e encartes); depois o dev redesenhou o app em torno da
**lista de compras** e escolheu a identidade **direção A** — é a versão descrita aqui.

Objetivos do dev: **o app mais fácil possível de entender** e **espaço para anúncios** (fonte de renda).

## Ideia central

A pessoa monta a **lista de compras** com as ofertas de hoje. Cada item vai para o grupo de um
**mercado** (o app mostra qual é o mais barato). A lista é **compartilhada por link** com quem vai ao
mercado, que marca o que já pegou — e quem mandou vê na hora.

## Telas (celular, 390×844)

| # | Tela | Arquivo | Conteúdo |
|---|---|---|---|
| 1 | Início | `Main.dc.html` | "Governador Valadares · atualizado hoje"; busca; card **Sua lista** ("5 itens em 3 mercados", por mercado, Ver lista, Compartilhar); **Anotar item na lista** (texto livre: "pão francês"); **Mercados perto de você** (pela localização, do mais perto ao mais longe); **Ofertas de hoje** com botão **Adicionar** e card de anúncio |
| 2 | Busca | `Busca.dc.html` | campo, filtro por mercado, ordenar, resultado **Patrocinado**, R$/kg, Adicionar; vazio: "Este mercado não tem arroz 5 kg no encarte desta semana. Mostramos só ofertas que valem hoje." |
| 3 | Mercados | `Mercados.dc.html` | "Do mais perto ao mais longe de você": distância, "encarte até 03/11", selo do clube ("Preço especial com bigmais+"); **Sugerir mercado** |
| 4 | Mercado | `Mercado.dc.html` | folheto e validade, **categorias** (Tudo, Açougue, Bebidas, Mercearia, Frios e laticínios, Limpeza), explicação do selo de clube, grade com Adicionar/quantidade, banner |
| 5 | Oferta | `Oferta.dc.html` | recorte do encarte, preço e preço de clube, **Onde comprar** (o mesmo produto nos outros mercados, "Menor preço", "Esta oferta"), "Ver o encarte completo", banner, barra fixa **Adicionar à lista** / quantidade |
| 6 | Minha lista | `Lista.dc.html` | "N itens em N mercados"; **grupos por mercado** (validade das ofertas, "1/3" pegos) + "Sem mercado definido" (anotados à mão); marcar pego, quantidade; **Compartilhar** |
| 7 | Lista recebida | `ListaCompartilhada.dc.html` | "Lista da Ana · atualizada há 5 min"; "Marque o que já pegou. A Ana vê na hora."; progresso; grupos por mercado com "ver no mapa"; **Avisar a Ana que terminei** |
| 8 | Formatos de anúncio | `Anuncios.dc.html` | os 4 formatos e as regras (abaixo) |
| Web 1 | Site · Início | `Web-Inicio.dc.html` | uma página: busca no topo, mercados, grade de ofertas com Adicionar/contador e a **lista fixa ao lado** (embaixo no celular); compartilhar com link único; faixa de anúncio. Feito em [site.md](site.md), sem a comparação ("a partir de", "trocar") nem "Entrar com Google" |
| Web 2 | Site · Lista recebida | `Web-ListaRecebida.dc.html` | abre pelo link do WhatsApp sem instalar nada: progresso, grupos por mercado com "Como chegar", marcar o que pegou, "Avisar que terminei", convite para ver as ofertas |
| — | Identidade · 3 direções | `Identidade-Direcoes.dc.html` | A "Vizinho amigo" (**escolhida**), B "Caderninho da casa" (Listinha), C "Carrinho esperto" (Juntaí) |
| — | Identidade · direção A | `Identidade-Marca.dc.html` | logo, ícone do app, componentes claro/escuro, tipografia, jeito de falar |

Navegação: **4 abas** — Início, Buscar, Mercados, Lista.

### Fluxos

- **Adicionar uma oferta**: "Adicionar" abre a folha **"Onde você vai comprar?"** com o produto nos
  mercados que têm oferta dele, o mais barato marcado ("Mais barato"); confirma "Comprar no Atacadão".
  O card vira um contador (− 2 +) com "no Atacadão · trocar". Aviso: "Café adicionado no Atacadão · Ver lista".
- **Compartilhar a lista**: "É sempre o mesmo link: quem receber vê a lista atualizada, separada por
  mercado." Permissão: **Só ver a lista** ("bom para mandar para quem vai ao mercado") ou **Ver e
  marcar o que já pegou** ("você acompanha o que já está no carrinho"). Copiar link ou enviar pelo WhatsApp.
  Link no formato `promocaonamao.com.br/l/K7Q2M`.
- **Quem recebe** marca os itens pegos (a dona da lista vê na hora) e avisa quando terminou.

## Identidade: direção A "Vizinho amigo"

- **Nome**: Promoção na Mão (nome curto embaixo do ícone: "Promoção" ou "Na Mão").
- **Símbolo**: etiqueta de preço com sorriso; o furo da etiqueta vira o olho. Área livre = a altura do furo.
- **Cor do app = escolha de quem usa** (a marca fica no símbolo, na tipografia e no jeito de falar):

| Cor | Hex |
|---|---|
| verde-água (padrão) | `#1E7A66` |
| roxo | `#5B4BC4` |
| azul-petróleo | `#2F5D8C` |
| framboesa | `#A8326E` |
| grafite | `#3F4A44` (gerado no modo "neutral" do Material: no padrão virava verde, igual ao verde-água) |

- **Tema**: Automático (o do aparelho, padrão), Claro ou Escuro, na mesma folha da cor ("Aparência", ícone de
  paleta na Início); os dois ficam guardados no aparelho. Os círculos da folha mostram a cor que o app usa no tema
  atual. Teste `app/test/tema_test.dart`: nenhuma cor pode gerar um tema parecido com o de outra.

  Tons derivados da cor escolhida (como no Material 3): fundo claro = cor misturada 95% com branco;
  realce = 82% branco; texto escuro = 50% preto. **Tema claro e escuro** (escuro: fundo `#141715`,
  superfície `#1E2220`, texto `#E3E6E2`).
- Neutros: texto `#1B1D1C`, secundário `#4A4F4C`, borda `#D9DDD9`/`#DADDD8`, fundo `#F4F8F7`.
- **Tipografia** (Google Fonts): **Fredoka 600** para títulos e preços (32 / 22 / 20); **Nunito**
  para textos (400 · 16 corpo, 700 · 14 botões, 400 · 12 legendas).
- **Forma**: cantos bem arredondados (cards 16 px, destaque 22 px), botões em pílula, chips 999 px.
- **Jeito de falar** (próximo, de vizinho): "Opa! O café que você sempre leva baixou no Atacadão." ·
  "Sua lista tá vazia. Bora dar uma olhada nas ofertas de hoje?" · "Prontinho! Mandamos a lista.
  Você vê na hora o que já foi pro carrinho."
- Cores dos mercados (bolinha com a sigla, sem logotipo): Big Mais `#1D4ED8`, Coelho Diniz `#B45309`,
  Atacadão `#0F766E`, Supermercados BH `#6D28D9`, Mart Minas `#BE123C`.

## Regras de clareza

- **O preço é o elemento mais forte** de cada card. Preço de clube com o nome do clube ("com bigmais+").
- Traduzir o encarte: "DE 24,90" → "Antes R$ 24,90"; "Lv. 12 Pg. 10" → "Leve 12, pague 10 · R$ 4,74
  cada"; data → "vale até terça, 03/11".
- Confiança: texto e **recorte do encarte original**; "Mostramos só ofertas que valem hoje"; "atualizado hoje".
- Acessibilidade: alvos ≥ 44 px, contraste ≥ 4,5:1, rótulos nos botões de quantidade ("Mais um café").

## Anúncios

| Formato | Selo | Onde | Para quem | Regra |
|---|---|---|---|---|
| Card no meio das ofertas | Anúncio | lista do Início, depois de cada 8 ofertas | comércio local | mesmo tamanho de uma oferta |
| Resultado patrocinado | Patrocinado | primeiro resultado da busca | mercados e marcas | só quando combina com o termo buscado |
| Banner na página | Anúncio | mercado (358×90) e oferta (358×100) | qualquer anunciante | abaixo do conteúdo principal |
| Mercado em destaque | Patrocinado | 1ª posição em "Mercados" | os mercados | um por vez, selo visível |

Regras para todos: sempre com selo "Anúncio" ou "Patrocinado"; nunca cobrir preço ou validade; no
máximo 1 a cada 8 ofertas; sem pop-up, tela cheia ou vídeo com som; **nunca na tela da Lista de compras**.

## O que o protótipo pede além da API atual

| Pede | Situação |
|---|---|
| Lista de compras com itens por mercado, quantidade, "pego", anotados à mão | tabelas `lista`/`lista_item` existem, mas exigem login e não têm mercado, "pego" nem texto livre |
| Lista compartilhada por link, com permissão e atualização na hora | não existe (precisa de link público seguro + tempo real) |
| "Onde comprar" / "Mais barato" | depende do **matching** (`oferta_vigente` por `produto_id`) |
| Mercados por distância | lat/lng das 21 lojas já existe; falta a localização do aparelho |
| Categorias no mercado | `oferta.secao` varia por rede; `categoria` vem do matching |
| Cor escolhida e tema escuro | só no app |
