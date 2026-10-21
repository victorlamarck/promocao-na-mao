# Ficha da Google Play

Material para publicar o app Android (flavor `prod`, `br.com.promocaonamao.app`). Preparado em 20/10/2026.

| Arquivo | O que é |
|---|---|
| [ficha.md](ficha.md) | nome, descrição curta (78) e completa (2923), categoria, contato, classificação IARC, público-alvo, anúncios |
| [seguranca-dos-dados.md](seguranca-dos-dados.md) | respostas do formulário "Segurança dos dados", conferidas no código, e pendências |
| `icone-512.png` | ícone 512×512 RGBA, redimensionado de `app/assets/icone/icone.png` |
| `destaque-1024x500.png` | imagem de destaque, sem transparência, texto longe das bordas |
| `capturas/` | 7 prints 1080×1920 do **app** (APK de dev num Pixel 9 Pro XL, 20/10/2026; dados do Supabase de dev), tema claro e cor padrão |
| `capturas-com-legenda/` | 4 desses prints numa moldura verde com legenda em Fredoka |

Como foram feitas: tela do celular em 9:16 (`adb shell wm size 1008x1920`), barra de status cortada (some
também a faixa DEV) e ampliado para 1080×1920. **Localização negada** durante as capturas: as distâncias
"814 m" etc. mostrariam onde o dev estava. Sem o painel Compartilhar (mostra o link do domínio de dev).
Refazer quando o app de prod estiver no ar, se a interface mudar. Os scripts ficaram no scratchpad da sessão.

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
