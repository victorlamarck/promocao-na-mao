# App Flutter (`app/`)

**Celular (Android/iOS).** O site é outro projeto, em Astro: ver [site.md](site.md). O app ainda roda no
Chrome (`-d chrome`) para desenvolver, mas não é publicado no web. Segue o protótipo de [design.md](design.md).
Decisões de estrutura (19/10/2026, `docs/decisoes.md` do repositório privado `promocao-na-mao-dados`): estado com `setState` /
`ChangeNotifier` (sem pacote), pastas por funcionalidade, `fromJson` à mão, rotas com `go_router`.

## Rodar

```
# o Supabase local vem do repositório privado promocao-na-mao-dados (clonado ao lado deste):
cd ../promocao-na-mao-dados && npx supabase start -x storage-api,imgproxy,edge-runtime,logflare,vector,supavisor,mailpit   # com Realtime
node extracao/importar.mjs                     # depois de um db reset
cd ../promocao-na-mao
cd app && flutter run -d chrome --dart-define-from-file=config/dev.json
flutter test                                   # lógica: preço, datas, anúncios, paginação, distância
flutter build web --dart-define-from-file=config/prod.json   # publicar
```

## Flavors: dev e prod

Cada flavor tem duas partes:

1. **Config do Dart**: `app/config/dev.json` / `prod.json`, lido com `--dart-define-from-file`
   (web e celular).
2. **Flavor nativo** (só celular, `--flavor dev|prod`): um app separado no aparelho, com o seu
   projeto Firebase. Os dois podem ficar instalados lado a lado.

| | dev | prod |
|---|---|---|
| ID Android / iOS | `br.com.promocaonamao.app.dev` | `br.com.promocaonamao.app` |
| Nome no celular | Promoção DEV | Promoção na Mão |
| Firebase | `promocaonamao-f08a7` | `promocaonamao-1` |

```
flutter run -d chrome --dart-define-from-file=config/dev.json               # web
flutter run --flavor dev --dart-define-from-file=config/dev.json            # celular
flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json
```

O app confere se o `--flavor` bate com o `FLAVOR` do json e não abre se não bater. No VS Code,
o Run tem "app (dev/prod)" para o web e "celular (dev/prod)" (`.vscode/launch.json`).

**Firebase** (`firebase_core`), com um projeto por flavor, no web e no celular. O `main.dart`
escolhe `firebase_options_dev.dart` ou `firebase_options_prod.dart` pelo `FLAVOR`. Nenhum desses
arquivos **vai para o git** (`.gitignore`). Para gerá-los de novo, rode de dentro de `app/`:

```
flutterfire configure --project=promocaonamao-f08a7 --out=lib/firebase_options_dev.dart --platforms=android,ios,web --android-package-name=br.com.promocaonamao.app.dev --ios-bundle-id=br.com.promocaonamao.app.dev --web-app-id=1:29175678966:web:fa9c303feea245f4e629d7 --android-out=android/app/src/dev/google-services.json --ios-out=ios/config/dev/GoogleService-Info.plist --ios-build-config=Debug-dev --yes
flutterfire configure --project=promocaonamao-1 --out=lib/firebase_options_prod.dart --platforms=android,ios,web --android-package-name=br.com.promocaonamao.app --ios-bundle-id=br.com.promocaonamao.app --web-app-id=1:37454516892:web:52e3d9c23b282d0dd89359 --android-out=android/app/src/prod/google-services.json --ios-out=ios/config/prod/GoogleService-Info.plist --ios-build-config=Release-prod --yes
```

**Sempre com os IDs explícitos.** Sem eles, o flutterfire usa o ID padrão do projeto e cria
apps cruzados no Firebase. Isso já aconteceu uma vez e deixou 2 apps sobrando para apagar.
O comando gera:
- `lib/firebase_options_<flavor>.dart`;
- `android/app/src/<flavor>/google-services.json`, que o plugin `com.google.gms.google-services`
  escolhe pelo flavor;
- `ios/config/<flavor>/GoogleService-Info.plist`, que a etapa "Firebase do flavor" do Xcode
  copia para dentro do app (o build falha se o arquivo faltar);
- `firebase.json`.

Num clone novo o app não compila sem esses arquivos. Rode os dois comandos acima, ou deixe que
a esteira os escreva a partir dos secrets.

No iOS, cada flavor é uma scheme (`dev`, `prod`) com as configurações `Debug-dev`, `Release-prod`
etc., que o `--flavor` do Flutter exige. As configurações sem flavor (`Debug`, `Release`) valem
como dev. **O iOS ainda não foi compilado**, porque precisa de um Mac ou da esteira.

No emulador Android, `127.0.0.1` é o próprio emulador. Para usar o Supabase local, rode antes
`adb reverse tcp:54321 tcp:54321`.

O `config/dev.json` vai para o git (só aponta para o Supabase local). O `config/prod.json` fica
só na máquina do dev e no secret `APP_CONFIG_PROD` da esteira.

- **dev**: Supabase local; faixa "DEV" no canto da tela. Sem arquivo nenhum, o app roda como dev.
- **prod**: o app **não abre** se faltar `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
  `CONTATO_ANUNCIE` ou `CONTATO_SUGESTAO` (erro dizendo qual falta) — evita publicar apontando
  para o banco local ou com contato vazio.

| Variável | Para quê | dev |
|---|---|---|
| `FLAVOR` | `dev` ou `prod` | `dev` |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | banco | Supabase local |
| `APP_URL` | base dos links de lista compartilhada (`<APP_URL>/l/<código>`) | endereço aberto no navegador |
| `ADSENSE_CLIENT`, `ADSENSE_SLOT` | AdSense nos espaços sem anúncio vendido | vazio → "Anuncie aqui" |
| `CONTATO_ANUNCIE`, `CONTATO_SUGESTAO` | links "Quero anunciar" e "Sugerir mercado" | WhatsApp sem número |

## Esteira (`.github/workflows/app.yml`)

Só roda se mudar `app/`: análise e testes, em PR e push na `main`. Não publica nada no web,
porque o web é o site ([site.md](site.md)).

O `APP_URL` do `config/prod.json` é `https://www.promocaonamao.com.br`: os links de lista que o app
compartilha (`/l/<código>`) abrem no site, para quem recebe não precisar instalar nada.

Secrets (*Settings → Secrets and variables → Actions*):

| Secret | Conteúdo |
|---|---|
| `FIREBASE_OPTIONS_DEV`, `FIREBASE_OPTIONS_PROD` | o arquivo `app/lib/firebase_options_<flavor>.dart` inteiro |
| `APP_CONFIG_PROD` | o arquivo `app/config/prod.json` inteiro |
| `FIREBASE_SA_DEV`, `FIREBASE_SA_PROD` | conta de serviço de cada projeto (*Firebase Hosting Admin*), usada pela esteira do **site** |

Android e iOS ainda não estão na esteira: entram quando houver conta nas lojas e assinatura.

## Estrutura

```
lib/
  main.dart                  Supabase, cor do app, lista do aparelho, AdSense, tema claro/escuro
  core/
    config.dart              flavor (config/*.json via --dart-define-from-file)
    tema.dart                identidade "Vizinho amigo": cor escolhida (5), Fredoka + Nunito, cores dos mercados
    modelos.dart             Oferta, Rede, Anuncio (fromJson)
    formato.dart             "R$ 4,99", "Vale até terça, 03/11", "Faltam 16 dias", "R$ 4,76 o kg"
    paginador.dart           lista paginada (.range) que descarta resposta de busca antiga
    localizacao.dart         distância até a loja mais perto de cada rede (pede a localização uma vez)
    widgets.dart             CardOferta, BotaoAdicionar/Contador, AvatarMercado, Etiqueta, avisos
    rotas.dart               go_router + 4 abas
  features/
    inicio/                  Sua lista, anotar item, mercados perto, ofertas de hoje (+ anúncio a cada 8)
    busca/                   buscar_ofertas, filtro por mercado, menor preço, patrocinado no topo
    mercado/                 Mercados (distância, destaque pago) e Mercado (categorias, banner)
    oferta/                  detalhe + "Adicionar à lista" fixo
    lista/                   Lista (estado + tempo real), Minha lista, compartilhar, lista recebida
    anuncios/                vendidos (Supabase) → AdSense (web) → "Anuncie aqui"
```

## Rotas (endereços compartilháveis no web)

`/` Início · `/buscar?q=` · `/mercados` · `/lista` (abas) · `/mercado/<slug>` · `/oferta/<id>` ·
`/l/<código>` (lista recebida).

## Lista de compras

- Sem login: a lista nasce no primeiro "Adicionar"; o código de dono fica no aparelho
  (`shared_preferences`). Backend: `docs/banco.md` do repositório privado `promocao-na-mao-dados`.
- "Adicionar" põe o item no grupo do **mercado da oferta** (sem comparar mercados no MVP);
  "Anotar item" cria item sem mercado.
- Compartilhar: "Só ver" ou "Ver e marcar o que já pegou"; copiar link ou WhatsApp. Quem recebe
  marca o que pegou e quem mandou vê na hora (Supabase Realtime, canal `lista-<id>`).
- "Esvaziar lista" (embaixo dos itens, com confirmação): `lista_esvaziar` (migration 18) tira todos os itens de uma vez;
  a lista e os links compartilhados continuam valendo (quem recebeu vê a lista vazia).
- "Apagar minha lista" (no fim da folha de compartilhar, com confirmação): `lista_apagar` (migration 10);
  os links param de abrir e o próximo "Adicionar" cria outra lista.
- Selo de validade (`SeloValidade`, `avisoValidade` em `core/formato.dart`): "Vence hoje" / "Vence amanhã"
  em amarelo no card e nos itens da lista; "Encarte venceu" em vermelho nos itens cuja oferta já acabou.

## Fale com a gente (sugestões e problemas)

Ícone de mensagem na Início → folha "Fale com a gente" (`features/sugestao/`): Sugestão ou Problema no app, texto
(até 1.000) e WhatsApp/e-mail opcional → `enviar_sugestao` (migration 19 do privado; tabela `sugestao`, lida no
painel do Supabase). Vai junto a versão do app (`versaoDoApp`: a esteira Android passa `--dart-define=VERSAO`;
build local = "dev") e a plataforma. Está na política de privacidade do site.

## Comparação entre mercados (decisão de 22/10/2026)

- **Tela da oferta:** `comparar_oferta(oferta_id)` (migration 17 do privado). Primeiro "O mesmo produto em outros
  encartes" (mesmo produto do catálogo) e, embaixo, "Parecidos" (mesmo nome genérico, outra marca ou tamanho; 5 e
  "Ver mais"). Tudo pelo R$/kg, litro ou unidade (`Oferta.porUnidadeValor`). Selo "Mais barato por litro" = sai
  mais em conta que esta oferta. Se a comparação falhar, a oferta aparece sem ela.
- **Busca:** selo "Mais barato por kg/litro" no menor R$/unidade entre os resultados já carregados com a mesma
  unidade (`maisBaratas` em `core/modelos.dart`; precisa de 2 ou mais).
- **Lista:** cada mercado mostra o total da compra (preço × quantidade) e, se tiver, o total com o clube
  (`totalDoMercado` em `features/lista/grupos.dart`). Anotados à mão (sem preço) ficam fora.

## Sem internet (sinal ruim no mercado)

- A lista (a minha e a recebida) é salva no aparelho a cada leitura. Sem conexão, aparece a última versão
  com o aviso "Sem internet" e o botão "Tentar"; marcar e editar ficam desligados até a conexão voltar.
- A primeira página do Início e de cada mercado ("Tudo") também ficam salvas (`core/cache.dart`, `comCache`).
  Busca, oferta e lista de mercados ainda precisam de internet.

## Ícones e abertura

- Fontes em `assets/icone/` (feitos do símbolo de `site/public/favicon.svg`): `icone.png`, `frente.png`
  (ícone adaptativo do Android) e as versões `_dev` com o selo "DEV", para não confundir os dois instalados.
  Regenerar: `dart run flutter_launcher_icons` (configs `flutter_launcher_icons-dev.yaml` / `-prod.yaml`).
  **Ele estraga o `project.pbxproj`** (passa para LF): confira com `git diff` e restaure; as linhas
  `ASSETCATALOG_COMPILER_APPICON_NAME` (`AppIcon-dev` / `AppIcon-prod`) já estão certas.
- Tela nativa (igual nos dois flavors): verde da marca com a etiqueta **sem o sorriso** (`abertura.png`),
  `dart run flutter_native_splash:create` (`flutter_native_splash.yaml`).
- Em seguida `core/abertura.dart` continua na mesma escala (48 unidades = 192 dp): a etiqueta balança
  pelo furo, o sorriso se desenha e tudo some em ~1 s, com as ofertas carregando por baixo. Pulada quando o
  app abre por link, no web e com "remover animações" do sistema.
- Depois dela, só na primeira abertura, as **boas-vindas** (`features/boas_vindas/`): 3 telas (ofertas de GV, comparar,
  lista compartilhada) com "Pular". "Primeira vez" = nada guardado no aparelho (SharedPreferences vazio), lido antes
  do Supabase: quem atualiza o app já tem cache/cor/lista e não vê. Não aparecem por link nem no web.

## Links do site abrem o app (Android)

O `AndroidManifest.xml` tem um `intent-filter` com `autoVerify` para `/l/`, `/oferta/` e `/mercado/`
no host do flavor (`linkHost` em `build.gradle.kts`). O go_router recebe o caminho e tira a barra do fim.
Os links que o app compartilha saem de `linkDoSite()` (`core/config.dart`). Detalhes e o lado do site
em [site.md](site.md#celular-abrir-no-app-ou-no-navegador).

## Publicar no Android

O build de release **exige a chave de publicação** (sem ela, falha avisando; nunca sai com a de debug):

1. Uma vez: `keytool -genkey -v -keystore %USERPROFILE%\promocaonamao-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
   e guarde o `.jks` e as senhas num lugar seguro (sem eles, não dá para atualizar o app na loja).
2. `app/android/key.properties` (fora do git):
   `storePassword=…`, `keyPassword=…`, `keyAlias=upload`, `storeFile=C:/Users/<você>/promocaonamao-upload.jks`.
3. `flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json`.
4. Com a Play App Signing, a digital que vai no `ANDROID_SHA256` do `APP_CONFIG_PROD` é a da
   **chave de assinatura do app** no Play Console (Configuração → Integridade do app).

### Pela esteira (`.github/workflows/android.yml`)

**Publica sozinha** quando chega ao `main` uma versão nova: um push no `main` que muda a linha `version:` do
`app/pubspec.yaml` (decisão de 22/10/2026: subir a versão é a decisão de publicar; mudar só um pacote do pubspec
não publica). O botão Actions → **Android** → Run workflow (branch `main`) fica para reenviar depois de uma falha.
A esteira compila o `.aab` prod assinado e manda para o **teste interno como rascunho**; liberar e promover a
produção é no Play Console. Rotina completa: skill `/subir-versao`.

A cada versão nova:
1. Suba a versão em `app/pubspec.yaml` (o número depois do `+` sempre; a Play recusa um versionCode repetido).
2. `release.txt` (raiz): as mudanças da versão em até 300 caracteres, uma por linha começando com `- `.
   Vira o "Novidades" do Play (pt-BR).
3. `versions.txt` (raiz): a mesma entrada no **topo**, no formato `v X.Y.Z`, linha em branco, os itens,
   linha de 119 `_`, linha em branco (fins de linha CRLF).

A esteira falha se o topo do `versions.txt` não for a versão do pubspec ou se o `release.txt` passar de 300.

Uma vez, os secrets (Settings → Secrets and variables → Actions), além dos do `app.yml`:

| Secret | De onde vem |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\promocaonamao-upload.jks"))` |
| `ANDROID_KEY_PROPERTIES` | o seu `android/key.properties`, trocando a linha do arquivo por `storeFile=upload.jks` |
| `GOOGLE_SERVICES_PROD` | conteúdo de `app/android/app/src/prod/google-services.json` |
| `PLAY_SERVICE_ACCOUNT_JSON` | chave JSON de uma conta de serviço (abaixo) |

Conta de serviço (é o "usuário robô" que a esteira usa para falar com o Play):
1. No Google Cloud (qualquer projeto, pode ser o do Firebase prod): IAM → Contas de serviço → Criar;
   sem papel no Cloud. Na conta criada: Chaves → Adicionar chave → JSON (baixa o arquivo).
2. Ative a **Google Play Android Developer API** nesse projeto.
3. Play Console → Usuários e permissões → Convidar usuário com o e-mail da conta de serviço;
   em Permissões do app, dê acesso ao Promoção na Mão com "Lançar em trilhas de teste" (e "Lançar no
   ambiente de produção" se for publicar em `production` pela esteira).
4. Cole o JSON no secret e apague o arquivo baixado.

A primeira versão de um app novo tem que ser enviada à mão no Play Console; enquanto o app não foi
publicado em nenhuma trilha, use status `draft`.

O manifest principal declara `INTERNET` (o Flutter só a põe no debug/profile) e `ACCESS_COARSE_LOCATION`;
o iOS tem o texto `NSLocationWhenInUseUsageDescription`.

## Anúncios no app (AdMob)

O AdSense é só para sites; no app, a rede do Google é o **AdMob** (mesmos anunciantes, pagamento junto com o
AdSense). Ordem de cada espaço (`EspacoAnuncioView`): anúncio vendido pelo dev → bloco do AdMob
(`features/anuncios/admob.dart`, 320×100, com o selo) → "Anuncie aqui" se o Google não tiver anúncio.
Só Android por enquanto; nunca na Lista.

| Onde | Dev | Prod |
|---|---|---|
| ID do app (`ca-app-pub-…~…`) | ID de teste do Google (fixo no `build.gradle.kts`) | `ADMOB_APP_ID` no `config/prod.json` → manifest. Build de release **falha sem ele** |
| ID do bloco (`ca-app-pub-…/…`) | bloco de teste do Google (`config.dart`) | `ADMOB_BLOCO` no `config/prod.json` (vazio = sem AdMob, só "Anuncie aqui") |

Configurar (dev, uma vez): criar a conta em admob.google.com **com a mesma conta Google do AdSense** (mesmo
`pub-…`), adicionar o app Android (`br.com.promocaonamao.app`; ligar à ficha da Play quando publicada), criar um
bloco **Banner**, pôr os dois IDs no `config/prod.json` e no secret `APP_CONFIG_PROD`. O site serve
`/app-ads.txt` (igual ao `ads.txt`), que o AdMob confere no site da ficha da Play. Nunca clicar nos próprios
anúncios de verdade: testar sempre no flavor dev (anúncios de teste).

iPhone: o `Info.plist` tem o ID de **teste** em `GADApplicationIdentifier` (sem ele o SDK fecha o app);
trocar pelo do app de iPhone no AdMob e ligar os anúncios lá quando o app for para a App Store.

## Avisos de ofertas novas (push)

**Como funciona.** O app assina, no Firebase Cloud Messaging (FCM), um **tópico** por mercado que a pessoa
quer acompanhar: `ofertas-<slug-da-rede>` (ex.: `ofertas-big-mais`, `ofertas-mart-minas`; o slug é o nome da
pasta em `encartes/`). Tópico é uma "lista de transmissão" do próprio FCM: quem envia não precisa saber os
aparelhos, só manda para o tópico — por isso o banco não guarda token de celular nenhum.

Quem envia é a esteira de dados (`.github/workflows/dados.yml` do repositório privado `promocao-na-mao-dados`):
1. `Importar encartes` roda `importar.mjs` com `IMPORTADOS=$RUNNER_TEMP/importados.json`; ele grava ali só os
   encartes **novos** desta rodada (`[{pasta, ofertas}]`; encarte já importado não entra, então repetir a esteira
   não repete aviso).
2. `Avisar ofertas novas` roda `node extracao/avisar.mjs <arquivo>`: junta por rede (uma notificação por rede por
   rodada, somando as ofertas; validade = a maior `validade_fim` dos encartes novos), pula encarte já vencido
   (fuso America/Sao_Paulo) e manda para o tópico pela API HTTP v1 do FCM. A mensagem:
   título "Ofertas novas no <rede>", texto "<N> ofertas, válidas até <dd/mm>. Toque para ver.",
   `data.rota` = `/mercado/<slug>` (o app abre essa tela), canal Android `ofertas`, prioridade normal.
3. Autenticação: a service account do Hosting (secrets `FIREBASE_SA_DEV` no `dev` → projeto promocaonamao-f08a7,
   `FIREBASE_SA_PROD` na `main` → promocaonamao-1). O script assina um JWT com a chave dela (`node:crypto`,
   sem dependência) e troca por um token OAuth2 do Google; o projeto é o `project_id` da própria SA.
4. Esse passo é `continue-on-error`: sem o secret ou sem permissão, sai um `::warning::` e a importação segue
   valendo. Erro numa rede não impede as outras.

Testar sem enviar: `node extracao/avisar.mjs --teste` (autoteste) e
`node extracao/avisar.mjs importados.json --seco` (imprime as mensagens; não chama a rede).
`FCM_VALIDAR=1` faz o FCM validar a mensagem de verdade sem entregar a ninguém.

**No app** (`features/avisos/avisos.dart`): o sino na tela do mercado pede a permissão de notificação
(Android 13+), assina/desassina o tópico e guarda os mercados ligados no aparelho. Tocar na notificação
abre `data.rota`. Ícone: `res/drawable/ic_notificacao.xml` (etiqueta branca), cor da marca.
shortcut: só Android; o iPhone precisa da chave APNs (conta Apple) e da capability "Push Notifications".

**Só o dev faz (uma vez por projeto, promocaonamao-f08a7 e promocaonamao-1):**
1. Google Cloud Console do projeto → **IAM e administrador → IAM** → na linha da service account
   `esteira-github@...` → editar → **Adicionar outro papel** → **"Firebase Cloud Messaging API Admin"**
   (`roles/firebasecloudmessaging.admin`) → Salvar.
2. Firebase Console → Configurações do projeto → **Cloud Messaging** → confirmar que a
   **"Firebase Cloud Messaging API (V1)"** está **ativada**.

## Crashlytics e Analytics

- **Crashlytics** (`main.dart`): erros do Flutter e da plataforma viram relatório no console do Firebase do
  flavor. Plugin Gradle `com.google.firebase.crashlytics`.
- **Analytics**: uma "tela vista" por troca de rota com o **molde** do caminho (`/l/:codigo`, `/oferta/:id`),
  nunca o caminho real, que levaria o código secreto da lista. **Sem ID de publicidade**: o manifest remove a
  permissão `AD_ID` e desliga `google_analytics_adid_collection_enabled`.
- Declarados na política de privacidade e em `docs/loja/seguranca-dos-dados.md`.

## Fontes

Fredoka 600 e Nunito 400/600/700/800 ficam **dentro do app** (`assets/fontes/`, licença OFL), declaradas no
`pubspec.yaml`; o pacote `google_fonts` saiu. Primeira abertura sem internet já mostra as letras certas.

## Ainda não feito

- iPhone: Universal Links (associated domains + `apple-app-site-association`), que dependem da conta Apple.
- Digital da chave de **publicação** no `ANDROID_SHA256` do prod, quando o app for para a Play Store.

- Recorte da imagem do encarte (a extração ainda não marca a posição da etiqueta).
- Comparação na lista: quanto a lista custaria em cada mercado (a tela da oferta e a busca já comparam).
- AdSense testado de verdade (precisa da conta aprovada); AdMob no celular.
- Builds Android/iOS publicados (assinatura, lojas). Plataformas e flavors já criados; o iOS nunca foi compilado.
