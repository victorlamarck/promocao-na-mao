# Site (`site/`)

O site público em <https://www.promocaonamao.com.br> é feito em **Astro**, separado do app Flutter, que
fica só para o celular. Ele segue as telas "Web" do protótipo (`Web-Inicio`, `Web-ListaRecebida`,
ver [design.md](design.md)). Decidido em 19/10/2026 (`docs/decisoes.md` do repositório privado `promocao-na-mao-dados`).

**Por que não o Flutter no web:** o Flutter web baixava ~3–4 MB antes da primeira tela e desenhava
tudo num canvas, que o Google não lê. O site baixa ~6 KB de HTML e ~10 KB de JavaScript na página
inicial (comprimidos), e cada oferta é texto que o Google indexa.

## Rodar

```
# o Supabase local vem do repositório privado promocao-na-mao-dados (clonado ao lado deste):
cd ../promocao-na-mao-dados && npx supabase start -x storage-api,imgproxy,edge-runtime,logflare,vector,supavisor,mailpit   # com Realtime
cd ../promocao-na-mao
cd site && npm install
npm run dev        # http://localhost:4321, com o Supabase local
npm test           # formatação: preço, validade, anúncios, distância
npx astro check    # tipos
npx astro build    # gera dist/
```

No `npm run dev`, as URLs `/l/<código>` não funcionam: o rewrite só existe no Firebase Hosting.
Para testar a lista recebida, use o build com um servidor que faça o rewrite.

## Como funciona

| Parte | Quando roda | Onde |
|---|---|---|
| Início, páginas `/mercado/<rede>/` | **no build**: o HTML já sai com as ofertas | `src/pages/`, dados em `src/lib/dados.ts` |
| Card de oferta | build (páginas) e navegador (busca) | `src/components/CardOferta.tsx` |
| "Adicionar" e contador | navegador, **um script só** para todos os cards (`data-oferta`) | `src/scripts/adicionar.ts` |
| Minha lista, contagem no topo | navegador (Preact) | `src/components/MinhaLista.tsx`, `ContagemLista.tsx` |
| Busca `/buscar?q=` | navegador, `buscar_ofertas` | `src/components/Busca.tsx` |
| Oferta `/oferta/<id>/` | **no build**, uma por oferta vigente (~850); destino do link que o app compartilha | `src/pages/oferta/[id].astro` |
| Política de privacidade `/privacidade/` | build; link no rodapé. **Mudou o que o site coleta? Atualize a página e a data** | `src/pages/privacidade.astro` |
| Lista recebida `/l/<código>` | navegador; tempo real no canal `lista-<id>` | `src/components/ListaRecebida.tsx` |

- **Banco:** as mesmas views e funções do app (`oferta_lista`, `rede_com_ofertas`, `buscar_ofertas`,
  `lista_*`, `anuncio_vigente`, `anuncios_da_busca`). O site não exigiu nenhuma mudança no banco.
- **Lista:** sem login, como no app. O código de dono fica no `localStorage` do navegador (a lista
  do site e a do app são listas diferentes). O link de compartilhar usa o código de **marcar**.
- **Leve:** as chamadas usam `fetch` puro. A biblioteca `supabase-js` (53 KB) só é baixada quando
  existe uma lista aberta, por causa do tempo real.
- **Anúncios:** o feed tem 1 anúncio a cada 8 ofertas (`intercalar`), mais uma faixa no fim da
  página. O espaço sem anúncio vendido vira "Anuncie aqui". A busca mostra os patrocinados no topo.
- **Google:** cada página declara o endereço oficial com www (`<link rel="canonical">`), mesmo se
  abrirem sem www. O site dev tem `noindex` em todas as páginas, para não concorrer com o prod.
- **Mercados:** aparecem em ordem alfabética. O botão "Perto de mim" pede a localização só quando
  a pessoa toca e reordena pela loja mais perto de cada rede. As coordenadas das lojas vêm no HTML.

## Celular: abrir no app ou no navegador

Quem recebe um link (`/l/<código>`, `/oferta/<id>`, `/mercado/<rede>/`) cai **na mesma página**, no
app ou no site:

- **Tem o app (Android):** o Android abre o link direto no app, na mesma tela (App Links). O app
  declara os endereços no `AndroidManifest.xml` (host por flavor: dev → `promocaonamao-f08a7.web.app`,
  prod → `www.promocaonamao.com.br`). O site confirma em `/.well-known/assetlinks.json`, com as
  digitais do certificado que assina o app (`ANDROID_SHA256`).
- **Abriu no navegador** (por exemplo, dentro do WhatsApp): uma folha pergunta **uma vez por aparelho**
  "Abrir no app" ou "Continuar no navegador" (`src/scripts/abrirApp.ts`). No Android, "Abrir no app"
  é um link de intent para a mesma página: abre o app se ele existir, senão a Play Store. No iPhone,
  o botão leva à App Store. Continuar no navegador fecha a folha e mantém a página.
- **Sem o link da loja na config, a folha não aparece** naquela plataforma, para ninguém ser mandado a uma loja
  onde o app ainda não existe.

Hoje: o **dev** tem a Play Store e a digital da chave de debug desta máquina (o APK dev feito aqui
abre os links do site dev). O **prod** fica vazio até o app estar na loja. Na publicação, preencher
`PLAY_STORE_URL` e `ANDROID_SHA256` com a digital da chave de publicação (ou a da Play App Signing,
no Play Console). O iPhone (Universal Links e `APP_STORE_URL`) depende da conta Apple.

## Selo de validade

`components/Vence.tsx` (`avisoValidade` em `lib/formato.ts`): "Vence hoje" / "Vence amanhã" no card e nos
itens da lista; "Encarte venceu" nos itens da lista. "Hoje" é o dia em GV (`hojeEmGV`), não o fuso de quem
roda: nas páginas estáticas vale o dia do build, que é refeito todo dia às 03:05.

## Segurança

- Cabeçalhos em `firebase.json` para todas as páginas: `nosniff`, `Referrer-Policy`, sem iframe de outro
  site (`X-Frame-Options`, `frame-ancestors`), `Permissions-Policy` (só localização, do próprio site).
- O endereço `/l/<código>` dá acesso à lista: **nunca carregar AdSense nem analytics nessa página**
  (o script leria a URL), e não ligar a exportação de logs do Hosting sem pensar nisso.
- Tempo real: no máximo uma leitura por segundo (`recarregarLogo` em `lib/lista.ts`).
- Prévias: caracteres de controle saem do texto (`escapar`), senão um nome vindo do PDF derruba o build.

## Prévia do link (WhatsApp)

Toda página tem `og:image` 1200×630, gerada no build por `src/pages/previa/[id].png.ts`
(SVG de `src/lib/previa.ts` → PNG com `sharp`): cada oferta mostra nome, preço e mercado
(`/previa/<id>.png`), a lista recebida usa `/previa/lista.png` e o resto `/previa/site.png`.
O WhatsApp não roda JavaScript, então a lista mostra a imagem genérica, sem os itens.
Letra: fontes do sistema (DejaVu Sans na esteira), não a Fredoka.

## Configuração (variáveis no build)

| Variável | Para quê | Sem ela |
|---|---|---|
| `PUBLIC_FLAVOR` | `dev` (faixa "DEV") ou `prod` | `dev` |
| `PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_PUBLISHABLE_KEY` | banco | Supabase local |
| `PUBLIC_CONTATO_ANUNCIE` | "Anuncie", "Para mercados" | WhatsApp sem número (no prod o build falha) |
| `SITE_URL` | endereço canônico e sitemap | `https://www.promocaonamao.com.br` |
| `PUBLIC_PLAY_STORE_URL`, `PUBLIC_APP_STORE_URL` | folha "Abrir no app" (Android / iPhone) | vazio: sem folha |
| `ANDROID_SHA256` | `/.well-known/assetlinks.json` (App Links) | vazio: lista vazia |

## Esteira (`.github/workflows/site.yml`)

As páginas são estáticas: uma oferta que vence hoje só sai do site quando ele é gerado de novo.
Por isso a esteira refaz o site também depois de cada importação (o `dados.yml` do repositório privado manda o aviso
`repository_dispatch: dados`, com o secret `SITE_DISPATCH_TOKEN`) e todo dia de madrugada.

| Evento | dev (promocaonamao-f08a7.web.app) | prod (www.promocaonamao.com.br) |
|---|---|---|
| PR em `site/` (para `dev` ou `main`) | só build | — |
| push no branch `dev` em `site/` | publica | — |
| push na `main` em `site/` (merge do PR `dev` → `main`) | — | publica |
| "Dados" terminou, 03:05 todo dia, botão | publica o branch `dev` | publica a `main` |

Cada site usa o seu banco: o dev usa o Supabase de dev (secret `APP_CONFIG_DEV`) e o prod usa o
de produção (`APP_CONFIG_PROD`), ver `docs/banco.md` do repositório privado `promocao-na-mao-dados`. O build roda
testes, tipos e build antes de publicar. O deploy usa
`FIREBASE_SA_DEV`/`FIREBASE_SA_PROD`. O `site/firebase.json` faz o rewrite de `/l/**` e o cache
longo de `/_astro/**`.

## Domínio

`promocaonamao.com.br`, registrado pelo dev. O endereço principal é **`www.promocaonamao.com.br`**,
e o sem www redireciona para ele. Assim o site abre do jeito que a pessoa digitar, e o Google vê
um endereço só (`SITE_URL` e `APP_URL` usam o www). No Firebase do projeto `promocaonamao-1`, em
*Hosting → Adicionar domínio personalizado*:

1. Adicionar `www.promocaonamao.com.br`. O Firebase mostra os registros DNS: um TXT para provar
   que o domínio é seu e o apontamento do www.
2. Adicionar `promocaonamao.com.br` e marcar **"Redirecionar para"** `www.promocaonamao.com.br`.
   Ele mostra os registros A do domínio sem www.
3. Cadastrar todos esses registros no registro.br (*Domínios → promocaonamao.com.br → DNS →
   Editar zona*). Um certificado HTTPS para cada endereço sai sozinho, em algumas horas.

## Ainda não feito

- Destaque pago de mercado (`mercado_destaque`) na lista de mercados; AdSense.
- Imagem do encarte no card (a extração ainda não marca a posição da etiqueta).
- Comparação na lista ("a partir de", "trocar") e "Entrar com Google": fora por decisão do dev. A página da oferta
  compara (`components/Comparacao.tsx`, `comparar_oferta` no navegador): o mesmo produto em outros encartes e os parecidos.
- Tema escuro (o protótipo web é só claro) e escolha de cor (só no app).
