# Play Console — Segurança dos dados

Respostas para *Política → Conteúdo do app → Segurança dos dados*, conferidas no código em 20/10/2026
(branch `dev`, commit `c4093e0`). Itens marcados **[confirmar]** precisam da decisão do dev.
Crashlytics, Analytics, push (20/10) e **AdMob (21/10)** já estão aqui; outro SDK novo → refaça.

## O que foi conferido

| Onde | O que tem |
|---|---|
| `app/pubspec.yaml` | `firebase_core`, `geolocator`, `go_router`, `google_fonts`, `shared_preferences`, `supabase_flutter`, `url_launcher`, `web`. **Sem** `firebase_analytics`, `firebase_crashlytics`, `firebase_messaging`, `google_mobile_ads`. |
| `app/lib/main.dart` | `Firebase.initializeApp`, **Crashlytics** (travamentos), **Analytics** (tela vista, com o molde da rota, ex. `/l/:codigo`, nunca o código) e **Messaging** (`features/avisos/`, tópico por mercado, só se a pessoa ligar o sino). Atualizado em 20/10/2026. |
| `AndroidManifest.xml` | `INTERNET` e `ACCESS_COARSE_LOCATION`. Sem `ACCESS_FINE_LOCATION`, `AD_ID`, câmera, contatos, arquivos. |
| `app/lib/core/localizacao.dart` | `Geolocator.getCurrentPosition(accuracy: LocationAccuracy.low)`; depois **baixa** as lojas (`loja: rede_id, lat, lng`) e calcula a distância no aparelho. A posição não entra em nenhuma chamada ao servidor. |
| `app/lib/features/lista/lista.dart` | Chamadas `lista_criar`, `lista_ler`, `lista_adicionar` (oferta ou **texto livre** até 120 caracteres), `lista_quantidade`, `lista_marcar`, `lista_nomear` (**nome do dono**, opcional, até 40), `lista_apagar`. O código de dono fica no aparelho (`shared_preferences`). |
| Busca (`busca_page.dart`, `anuncios.dart`) | O termo digitado vai para `buscar_ofertas` / `anuncios_da_busca`. Não há tabela que guarde buscas nem cliques em anúncios (`supabase/migrations`). |
| Retenção (`supabase/migrations/20261021120000_seguranca.sql`) | Limpeza diária (pg_cron): listas vazias com mais de 1 dia e listas sem mudança há 6 meses. |
| Backup (`.github/workflows/backup.yml`) | Backup diário das listas de produção como artifact do GitHub Actions, **guardado 30 dias**. |
| Política (`site/src/pages/privacidade.astro`) | Lista, nome opcional, localização só no aparelho, busca não ligada à pessoa, Supabase em São Paulo, apagar lista, 6 meses, e-mail. |

## Visão geral (primeira tela do formulário)

| Pergunta | Resposta |
|---|---|
| O app coleta ou compartilha algum dos tipos de dados exigidos? | **Sim** |
| Todos os dados coletados são criptografados em trânsito? | **Sim** — Supabase só por HTTPS (conferido: `SUPABASE_URL` do `config/prod.json` local começa com `https://`); fontes do Google e links externos também são HTTPS. |
| Vocês oferecem um jeito de o usuário pedir a exclusão dos dados? | **Sim** — botão "Apagar minha lista" (apaga na hora, `lista_apagar`) e pedido por e-mail (oi.promocaonamao@gmail.com). Sem conta, então não há "excluir conta". |
| Link para pedir a exclusão (o Console pede uma URL) | https://www.promocaonamao.com.br/apagar-dados (página só de exclusão, como a Play pede: nome do app, passos, o que é apagado e o que fica). **Não** marcar "excluídos automaticamente em 90 dias": a lista parada só some em 6 meses e as cópias de segurança ficam 30 dias. |
| O app passou por análise de segurança independente (MASA)? | Não |
| Os dados são de um app para crianças (Famílias)? | Não |

## Tipos de dados

"Coletado" = sai do aparelho para nós (ou para um SDK). Mandar ao Supabase, que é **prestador de
serviço** (processa por nossa conta), **não conta como compartilhar**. Mostrar a lista para quem a
pessoa mandou o link é ação iniciada por ela, com expectativa clara, e também **não conta como
compartilhar** (regra do Play).

### 1. Localização aproximada — **não declarar**

- Coletada? **Não.** Usada só no aparelho para ordenar os mercados por distância; não é enviada nem
  guardada (conferido em `localizacao.dart`: a posição só entra em `distanciaKm`, local).
- O Play não exige declarar dado processado só no aparelho. A permissão `ACCESS_COARSE_LOCATION` continua
  no manifest e está justificada na política.
- Localização exata: não pedida (sem `ACCESS_FINE_LOCATION`).

### 2. Atividade no app → Outro conteúdo gerado pelo usuário — **declarar**

O que é: os itens da lista de compras (ofertas escolhidas, quantidades, "pego") e os itens anotados à mão
(texto livre, até 120 caracteres), guardados no Supabase.

| Pergunta | Resposta |
|---|---|
| Coletado | Sim |
| Compartilhado | Não |
| Processado temporariamente (efêmero)? | Não — fica guardado até a pessoa apagar ou 6 meses sem mudança |
| Obrigatório ou opcional | **Opcional** — dá para ver ofertas e buscar sem montar lista |
| Finalidades | **Funcionalidade do app** (só essa) |

### 3. Informações pessoais → Nome — **declarar** (conservador)

O que é: o campo "Seu nome (aparece para quem recebe)", até 40 caracteres, guardado em `lista.nome_dono`.
Pode ser apelido; mas o mais comum é a pessoa pôr o nome dela, então é nome.

| Pergunta | Resposta |
|---|---|
| Coletado | Sim |
| Compartilhado | Não (só aparece para quem abre o link que a pessoa mandou) |
| Efêmero | Não |
| Obrigatório ou opcional | **Opcional** |
| Finalidades | **Funcionalidade do app** |

### 4. Atividade no app → Histórico de pesquisa no app — **declarar como efêmero** [confirmar]

O que é: o termo digitado na busca, enviado ao Supabase para achar as ofertas. Não é guardado em
tabela nenhuma nem ligado à lista ou à pessoa.

| Pergunta | Resposta |
|---|---|
| Coletado | Sim (sai do aparelho) |
| Compartilhado | Não |
| Efêmero | **Sim** — usado só para responder a busca |
| Obrigatório ou opcional | Opcional |
| Finalidades | Funcionalidade do app |

Por que declarar mesmo assim: o Play considera "coletado" tudo que sai do aparelho, e a regra do efêmero
existe justamente para isso. Declarar é o lado seguro. **[confirmar]** se os logs do Supabase (API/Postgres)
registram o corpo das chamadas `rpc` — se registrarem, o termo fica alguns dias nos logs do Supabase; o
efêmero continua defensável (log técnico do prestador), mas vale olhar no painel.

### 5. Identificadores do dispositivo ou outros IDs — **declarar "IDs do dispositivo ou outros"** (atualizado em 20/10/2026)

- Com Analytics, Crashlytics e Messaging (20/10/2026), o Firebase cria o **installation ID** e o token de
  notificação → coletado, **não compartilhado**, obrigatório, finalidade Funcionalidade do app e Análise.
  O app **não** lê Android ID, IMEI nem **ID de publicidade** (a permissão `AD_ID` é removida no manifest e
  `google_analytics_adid_collection_enabled` = false).
- O código secreto da lista é aleatório, criado pelo servidor, e identifica **a lista**, não o aparelho
  nem a pessoa; some com "Apagar minha lista". Minha leitura: não é "ID do dispositivo".
  Se quiser o lado mais conservador, declare "Outros IDs" → coletado, não compartilhado, obrigatório
  para a lista, finalidade Funcionalidade do app. Não muda nada para quem usa.

### 6. Endereço IP e dados técnicos de acesso — **não declarar**

O Supabase (e o Google Play) registram IP e data/hora de cada acesso, como qualquer servidor. O Play não tem
"endereço IP" como tipo de dado; só vira declaração se for usado para localizar a pessoa (não é). A política
já cita esses dados técnicos.

### 7. Não coletados (marcar nada)

Localização exata · e-mail · telefone · endereço · contatos · fotos e vídeos · áudio · arquivos ·
agenda · mensagens · informações financeiras · saúde · navegação na web · apps instalados ·
ID de publicidade (sem AdMob; `AD_ID` removido).

## Com o AdMob (anúncios do Google no app, 21/10/2026)

Fonte: [divulgação de dados do Google Mobile Ads SDK](https://developers.google.com/admob/android/privacy/play-data-disclosure)
— o SDK **coleta e compartilha** automaticamente, para **publicidade, análise e prevenção de fraudes**: endereço IP
(usado para estimar a localização geral), interações com o app (abertura, toques), diagnóstico (desempenho) e
identificadores (ID de publicidade, app set ID). Tudo com TLS. Por isso, além do resto:

- **ID de publicidade** (tela própria do Console): **Sim** → finalidades **Publicidade ou marketing**, **Análise**
  e **Segurança, conformidade e prevenção de fraudes**. O manifest volta a ter `AD_ID` (vem do SDK).
- **Localização aproximada** passa a ser declarada: coletada **e compartilhada** pelo AdMob (pelo IP), obrigatória,
  finalidades Publicidade, Análise e Prevenção de fraudes. A distância até os mercados continua só no aparelho.
- **Interações com o app**, **Diagnóstico** e **IDs do dispositivo ou outros** ganham "compartilhado: Sim" e as
  finalidades Publicidade e Prevenção de fraudes, além das que já tinham.

## Resumo para conferir antes de enviar

Como ficou cadastrado no Console em 21/10/2026 (8 tipos; "Outros dados de desempenho do app" **desmarcado**).
"Fraudes" = *Prevenção de fraudes, segurança e compliance*.

| Categoria → Tipo | Coletados | Compartilhados | Efêmero | Obrigatório/opcional | Finalidades da coleta | Finalidades do compartilhamento |
|---|---|---|---|---|---|---|
| Informações pessoais → Nome | Sim | Não | Não | Opcional | Funcionalidade | — |
| Local → Local aproximado (AdMob, pelo IP) | Sim | **Sim** | Não | Obrigatória | Publicidade, Análise, Fraudes | Publicidade, Análise, Fraudes |
| Informações e desempenho → Registros de falhas (Crashlytics) | Sim | Não | Não | Obrigatória | Análise | — |
| Informações e desempenho → Diagnóstico (Crashlytics, AdMob) | Sim | **Sim** | Não | Obrigatória | Análise, Fraudes | Análise, Fraudes |
| Atividade em apps → Interações no app (Analytics, AdMob) | Sim | **Sim** | Não | Obrigatória | Análise, Publicidade, Fraudes | Publicidade, Análise, Fraudes |
| Atividade em apps → Histórico de pesquisa no app | Sim | Não | **Sim** | Opcional | Funcionalidade | — |
| Atividade em apps → Outro conteúdo gerado pelo usuário (lista) | Sim | Não | Não | Opcional | Funcionalidade | — |
| Identificadores do dispositivo e outros IDs (Firebase, push, ID de publicidade) | Sim | **Sim** | Não | Obrigatória | Funcionalidade, Análise, Publicidade, Fraudes | Publicidade, Análise, Fraudes |

Criptografia em trânsito: Sim. Pedido de exclusão: Sim.

## Pendências e riscos para o dev

1. ~~**Backup de 30 dias.**~~ Resolvido: a política cita o backup de 30 dias e o GitHub (20/10/2026).
   **Backup de 30 dias.** Depois de "Apagar minha lista" (ou da limpeza de 6 meses), a lista ainda existe
   por até 30 dias no backup do GitHub Actions. A política diz "ela some na hora do nosso banco de dados" —
   é verdade para o banco, mas vale acrescentar uma linha ("cópias de segurança são apagadas em até 30 dias")
   e citar o GitHub como prestador. Não mexi na política (site/ está fora do escopo).
2. ~~**A política fala do site.**~~ Resolvido: a política cobre o app, o Firebase e os avisos (20/10/2026).
   **A política fala do site.** O texto diz "o site", "neste navegador", "armazenamento local do navegador".
   Para a Play, o ideal é a política citar também o app Android: código guardado no aparelho, localização
   pela permissão do sistema, e o Firebase (hoje só inicializado). Sugestão: um parágrafo "No app para
   celular" na mesma página.
3. **Quando entrar AdMob**: declarar ID de publicidade (coletado e compartilhado, Publicidade), interações
   no app/diagnóstico conforme o formulário do SDK, ID de publicidade = Sim na outra declaração, e
   atualizar a política (hoje fala de AdSense no site).
4. ~~Quando entrar Crashlytics/Analytics/Messaging~~ (entraram em 20/10/2026, declarados acima): declarar registros de falhas, diagnóstico, interações,
   IDs do dispositivo (installation ID) conforme o que o SDK coleta.
5. Conferir no APK/AAB final (merged manifest) que nenhuma dependência adicionou permissões ou o `AD_ID`.
