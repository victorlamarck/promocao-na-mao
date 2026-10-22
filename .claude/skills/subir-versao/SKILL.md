---
name: subir-versao
description: Sobe uma versão nova do app Android para o teste interno da Play. Atualiza os branches, vê o que mudou desde a última versão, escreve as notas (release.txt e versions.txt), testa o release no celular do dev, abre os PRs e acompanha a esteira Android, que publica sozinha quando a versão nova chega ao main. Use quando o dev disser "subir versão", "nova versão do app", "gerar o .aab" ou rodar /subir-versao.
argument-hint: "[X.Y.Z]"
---

# Subir versão do app

O dev roda isto quando quer mandar o app para a Play. Você conduz e para nos pontos marcados com **(dev)**.
O passo a passo de referência é `docs/app.md#publicar-no-android`; não repita aqui o que já está lá.

Comandos rodam **neste repositório** (`promocao-na-mao`); aberto pela pasta controladora `C:\projetos\promocao`,
faça `cd promocao-na-mao` antes. O Flutter fica em `app/`.

## 1. Branches em dia (nunca gerar de código velho)

1. `git status`: com mudança local, pergunte ao dev o que fazer (não descarte nada).
2. `git fetch origin --prune` e compare local × GitHub (`git rev-list --left-right --count main...origin/main`, o mesmo
   para `dev`). Commit só local → pergunte antes de seguir.
3. Atualize só com fast-forward: `git fetch origin main:main dev:dev` (no branch em uso: `git merge --ff-only`).
4. Mudança de API do banco nesta versão (função/view nova): confira se ela já está em produção (`main` do privado
   `promocao-na-mao-dados`; a integração do Supabase aplica as migrations no merge). App novo chamando função que não
   existe em prod quebra para todo mundo.

## 2. O que muda nesta versão

1. Versão atual: `version:` em `app/pubspec.yaml` (ex.: `0.2.4+8`) e o topo do `versions.txt`.
2. Mudanças desde a última versão:
   `git log --oneline $(git log -1 --format=%H -S"version: <atual sem o +N>" -- app/pubspec.yaml)..origin/dev -- app/`.
   Nada em `app/` → diga que não há o que publicar e pare.
3. Crashlytics (MCP `firebase`, app prod `1:37454516892:android:ad7ea6ba3b6983a9d89359`): a versão atual já está no ar?
   Algum erro novo dela que esta versão deveria corrigir? Conte ao dev.
4. Número novo: `$ARGUMENTS` se veio; senão proponha (correção → `X.Y.Z+1`; função nova → `X.Y+1.0`) e
   **(dev)** confirme. O número depois do `+` **sempre** sobe 1 (a Play recusa versionCode repetido).

## 3. Notas da versão (para quem usa o app, não para programador)

Escreva em português simples, do ponto de vista de quem usa ("Compare o preço com outros mercados"), sem nome de
função, tabela ou arquivo. **(dev)** Mostre e peça aprovação antes de gravar.

- `release.txt` (raiz): até **300 caracteres** contando as quebras de linha; uma mudança por linha começando com `- `;
  sem linha em branco no fim. Vira o "Novidades" da Play.
- `versions.txt` (raiz): a mesma entrada **no topo**: `v X.Y.Z`, linha em branco, os itens, linha de **119 `_`**,
  linha em branco. Fins de linha **CRLF** (grave com script e confira com `head -c 300 versions.txt | od -c`).
- `app/pubspec.yaml`: `version: X.Y.Z+N`.

A esteira Android recusa se o topo do `versions.txt` não for `v` + a versão do pubspec ou se o `release.txt` passar de 300.

## 4. Testar antes (o que só quebra no release)

1. `cd app && flutter analyze && flutter test` — tudo verde.
2. Release no celular **(dev: o Pixel está ligado no cabo com depuração USB?)**. Erros do R8 (WorkManager, JNI do
   shared_preferences, ANR) só aparecem no build de release; o flavor dev passa pelo mesmo R8 sem mexer no app da Play:
   - config temporária **fora do git** (pasta temporária da sessão) com `FLAVOR=dev`, `SUPABASE_URL` do Supabase de dev
     (`https://tqhhizuthfqhmtiilhiq.supabase.co`) e a chave publishable dele (MCP `supabase` → `get_publishable_keys`);
   - `flutter build apk --release --flavor dev --dart-define-from-file=<essa config>` e `adb install -r` o APK;
   - **(dev)** abrir, trocar a cor, fechar e reabrir (a cor fica), rolar até o anúncio de teste, abrir uma oferta,
     adicionar à lista, abrir sem internet, e mexer no que esta versão mudou;
   - `adb logcat -d` e contar `ANR in`, `FATAL EXCEPTION` e `NoSuchMethodError`: tem de dar **0**.
   Sem celular: diga que o teste do release ficou de fora e que esse é o risco, e só siga se o dev mandar.
3. Pacotes travados de propósito no pubspec (`shared_preferences_android`, `webview_flutter_wkwebview`): não atualize.

## 5. PRs (o dev faz os merges)

1. Branch `versao-X.Y.Z` a partir do `dev` atualizado; commit "App X.Y.Z+N: <resumo>" com o pubspec, o `release.txt`
   e o `versions.txt`.
2. PR → `dev`. **(dev)** merge.
3. PR `dev` → `main` (título "Dev"). **(dev)** merge.

## 6. Mandar para a Play (sozinho)

1. O merge `dev` → `main` com a versão nova **dispara a esteira Android sozinho** (ela publica quando a linha
   `version:` do pubspec muda no `main`). Não rode o botão: sairia um envio repetido.
2. Acompanhe: `gh run list -R victorlamarck/promocao-na-mao -w Android -L 1` e `gh run watch <id>`.
   A esteira compila o `.aab` prod assinado e manda para o **teste interno como rascunho**.
3. Falhou → mostre o passo e o erro do log (`gh run view --log-failed`); não tente de novo sem entender. Corrigido
   sem mudar a versão → aí sim o botão: `gh workflow run Android -R victorlamarck/promocao-na-mao --ref main`.
4. **(dev)** No Play Console: liberar o rascunho do teste interno (e, quando quiser, promover para produção).

## 7. Fechar

Resumo: versão, o que entrou, resultado do teste no celular (ou que ficou de fora), link da execução da esteira e
o que falta no Play Console. Lembre de olhar o Crashlytics da versão nova depois que ela chegar aos celulares.
