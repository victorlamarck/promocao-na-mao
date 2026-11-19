# Ficha da Google Play

Material para publicar o app Android (flavor `prod`, `br.com.promocaonamao.app`). Preparado em 20/10/2026.

| Arquivo | O que é |
|---|---|
| [ficha.md](ficha.md) | nome, descrição curta (78) e completa (2923), categoria, contato, classificação IARC, público-alvo, anúncios |
| [seguranca-dos-dados.md](seguranca-dos-dados.md) | respostas do formulário "Segurança dos dados", conferidas no código, e pendências |
| `icone-512.png` | ícone 512×512 RGBA, redimensionado de `app/assets/icone/icone.png` |
| `destaque-1024x500.png` | imagem de destaque, sem transparência, texto longe das bordas |
| `capturas-com-legenda/` | 5 telas 1080×1920 do app (versão 0.10.0, dados de prod de 19/11/2026) numa moldura verde com legenda em Fredoka: início, gráfico de preço, busca, lista, mercados |

Como foram feitas: com os mesmos scripts das capturas da App Store ([app-store/tools/](app-store/tools/), passo a passo no
[README de lá](app-store/README.md)), moldura com `node moldura.mjs <cru> <saida> play`. Na Play o celular aparece
cortado mais acima, por isso a tela do gráfico tem uma captura própria, mais rolada (`roteiro-play-preco.json`).

## O que só o dev faz no Play Console

1. Criar a conta de desenvolvedor (US$ 25), como organização (VL Desenvolvimento e Tecnologia LTDA, D-U-N-S),
   e fazer a verificação de identidade.
2. Criar o app: nome "Promoção na Mão", idioma pt-BR, app, gratuito.
3. Gerar a chave de upload e o AAB (`docs/app.md#publicar-no-android`), ativar a Play App Signing e pôr a
   SHA-256 da chave de assinatura no `ANDROID_SHA256` do `APP_CONFIG_PROD` (App Links).
4. Preencher a ficha (ficha.md), subir os gráficos e responder as declarações de *Conteúdo do app*
   (classificação, público-alvo, anúncios, segurança dos dados, ID de publicidade, acesso ao app).
5. Confirmar os itens **[confirmar]** de seguranca-dos-dados.md e decidir sobre a política (backup de 30 dias,
   parágrafo sobre o app).
6. Teste fechado: conta pessoal nova exige 12 testadores por 14 dias antes da produção; conta de organização
   não tem essa exigência (confira a regra atual no Console).
7. Enviar para revisão.
