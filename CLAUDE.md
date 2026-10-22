# Promoção na Mão — app e site (repositório público)

Ofertas dos supermercados de Governador Valadares-MG numa lista só. Documentação em [`docs/`](docs/README.md).
**Este repositório é público**: app Flutter e site Astro. Banco, coleta e extração dos encartes ficam no
repositório **privado `promocao-na-mao-dados`** (clonado ao lado: `../promocao-na-mao-dados`).

## Repositório público: cuidados
- Nada secreto no git: chaves e configs ficam nos secrets do GitHub e em arquivos ignorados
  (`app/config/prod.json`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options_*.dart`,
  `key.properties`, `upload.jks`, contas de serviço `promocaonamao-*.json`). Antes de commitar, olhar o `git status`.
- O que pode aparecer: a chave **publishable** do Supabase e os IDs do AdMob (vão dentro do app de qualquer jeito).
- Esteiras: PR de fork não recebe secrets; nenhuma usa `pull_request_target`. Não criar esteira que rode código de PR
  de fora com secret.
- Não escrever aqui estratégia de negócio, coletores ou dados dos supermercados (vão para o repositório privado).

## Stack
- Flutter (`app/`, celular) e Astro + Preact (`site/`, web). Backend: Supabase (Postgres) do repositório privado.
- Desenvolvedor domina Flutter; **partes de backend devem ser explicadas didaticamente**.

## API do banco (o contrato com o repositório privado)
Só leitura pela chave publishable (RLS) e funções `security definer`; nada escreve direto nas tabelas.
- Views: `oferta_lista` (uma linha por oferta vigente), `rede_com_ofertas` (mercados com ofertas hoje; `atualizado_em`
  = última importação), `anuncio_vigente`; tabela `loja` (lat/lng).
- Funções: `buscar_ofertas(termo)`, `anuncios_da_busca(termo)`, `secoes_da_rede(slug)`, `lista_criar`, `lista_ler`,
  `lista_adicionar`, `lista_quantidade`, `lista_marcar`, `lista_nomear`, `lista_esvaziar`, `lista_apagar`. Tempo real: canal `lista-<id>`.
- Mudança na API: primeiro o PR com a migration no repositório privado, depois o PR aqui.
- Regras: "hoje" no fuso America/Sao_Paulo; ofertas vencidas são apagadas do banco todo dia.

## Design — detalhes em `docs/design.md`
- Em torno da **lista de compras**: adicionar oferta → "Onde você vai comprar?" (mais barato marcado) → lista
  agrupada por mercado → **compartilhada por link** (só ver / marcar o que pegou). 4 abas: Início, Buscar, Mercados, Lista.
- Identidade "Vizinho amigo": Fredoka (títulos/preços) + Nunito; **cor do app escolhida por quem usa**
  (verde-água #1E7A66 padrão, roxo, azul-petróleo, framboesa, grafite); claro e escuro.
- Anúncios = renda do dev: nativos, selo "Anúncio"/"Patrocinado", máx. 1 a cada 8 ofertas, sem pop-up, nunca na Lista.
- O app mostra o texto original e a imagem do próprio encarte; "Atualizado hoje às 08:12" na Início.

## Site — detalhes em `docs/site.md`
- Páginas de ofertas geradas no build (refeito depois de cada importação, por aviso do repositório privado, e às 03:05);
  busca e lista no navegador com as mesmas funções do banco. www.promocaonamao.com.br.
- `cd site && npm run dev`; `npm test`; `npx astro check`.
- Páginas exigidas pela Play: `/privacidade` (AdSense e AdMob), `/apagar-dados`, `ads.txt` e `app-ads.txt`.
  Material da loja (ficha, segurança dos dados, capturas) em `docs/loja/`.

## App Flutter (celular) — detalhes em `docs/app.md`
- `app/`: setState/ChangeNotifier (sem pacote), pastas por funcionalidade, fromJson à mão, go_router.
- `cd app && flutter run -d chrome --dart-define-from-file=config/dev.json` (Supabase local do repositório privado); `flutter test`.
- Flavors dev/prod: `app/config/*.json` + `--flavor` no celular (Firebase por flavor, arquivos fora do git); prod não abre com config obrigatória vazia.
- Versão na Play (teste interno): **0.2.3+7** (`br.com.promocaonamao.app`). Firebase só Crashlytics/Analytics/push.
- Anúncios: os do comércio local (`anuncio`) e, onde não há, **AdMob** (`features/anuncios/admob.dart`, `largeBanner`, só
  Android; IDs de teste no dev, reais em `config/prod.json` → secret `APP_CONFIG_PROD`; build prod falha sem `ADMOB_APP_ID`).
  iOS ainda com o ID de teste no `Info.plist`. `docs/app.md#anúncios-no-app-admob`.
- **Erros do R8 só aparecem no release** (0.2.0–0.2.2: WorkManager do AdMob, shared_preferences 2.5): antes de cada `.aab`,
  testar o release do flavor dev no celular (abrir, trocar a cor, fechar/reabrir, anúncio, lista, sem internet; logcat
  sem ANR/FATAL). Travados de propósito no `pubspec.yaml`: `shared_preferences_android` 2.4.28 e
  `webview_flutter_wkwebview` 3.25.1 (iOS); `work-runtime` 2.12.0 forçado no `build.gradle.kts`.

## Produção e esteiras
- **Branches:** trabalho em PRs para `dev` (publica o site dev); PR `dev` → `main` publica o prod.
- `.github/workflows/`: `app.yml` (análise/testes), `android.yml` (só no botão, do `main`: `.aab` prod assinado → teste
  interno do Play como rascunho; **toda versão nova do app atualiza `release.txt` (≤300 caracteres) e o topo do
  `versions.txt`**, formato em `docs/app.md#publicar-no-android`), `ios.yml` (só no botão; roda em Mac) e `site.yml`
  (dev → site dev, `main` → prod; também no aviso `repository_dispatch: dados`, às 03:05 e no botão).
- Repositório público: minutos das esteiras grátis (inclusive Mac).
- MCP (`.mcp.json`, só leitura): `firebase` (Crashlytics; projetos `promocaonamao-f08a7` dev, `promocaonamao-1` prod).
  O 1º start frio é lento: `MCP_TIMEOUT` alto no `.claude/settings.local.json`.
