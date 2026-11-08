# App Privacy (rótulo de privacidade da App Store)

Respondido em 08/11/2026, conferido no código: Analytics, Crashlytics, Push (FCM), AdMob, lista compartilhada
(`lista_*` no banco) e "Fale com a gente" (`enviar_sugestao`). Sem login e sem ATT. Equivale ao
[formulário da Play](../seguranca-dos-dados.md).

- Privacy Policy URL: `https://www.promocaonamao.com.br/privacidade`
- "Do you or your third-party partners collect data from this app?" **Yes**

| Tipo de dado | Purposes | Linked to identity? | Tracking? |
|---|---|---|---|
| Contact Info → Email Address | App Functionality | **Yes** | No |
| Contact Info → Phone Number | App Functionality | **Yes** | No |
| User Content → Customer Support | App Functionality | No | No |
| User Content → Other User Content | App Functionality | No | No |
| Identifiers → Device ID | App Functionality, Analytics, Third-Party Advertising | No | No |
| Usage Data → Product Interaction | Analytics, Third-Party Advertising | No | No |
| Usage Data → Advertising Data | Third-Party Advertising | No | No |
| Location → Coarse Location | Analytics, Third-Party Advertising | No | No |
| Diagnostics → Crash Data | App Functionality | No | No |
| Diagnostics → Performance Data | App Functionality, Analytics | No | No |
| Diagnostics → Other Diagnostic Data | App Functionality, Analytics | No | No |

Não declarados, de propósito:
- **Precise Location**: o GPS só ordena os mercados por distância no aparelho; não sai do celular.
- **Search History**: o termo buscado vai ao banco, mas não é gravado.
- Name, Financial, Health, Contacts, Browsing History, Purchases, Sensitive Info: não coletados.

Mudar se: entrar a pergunta de rastreamento (ATT) → Device ID e Advertising Data passam a "Tracking: Yes";
entrar login → quase tudo vira "Linked: Yes".
