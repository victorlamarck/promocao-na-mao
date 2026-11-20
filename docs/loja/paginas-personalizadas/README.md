# Páginas personalizadas das lojas (t16, t17)

Prints por público, do app 0.11.1 em produção no Samsung S10+ (20/11/2026), com ofertas reais do dia.

| Público | Prints | Legendas |
|---|---|---|
| Jovens | busca, comparar preço entre mercados, compartilhar a lista | `legendas-jovens.json` |
| Adultos | lista da semana por mercado, quanto a lista sai em cada mercado, sino de aviso | `legendas-adultos.json` |

- `cru/<público>/`: a tela do celular sem a barra de status. O código da lista foi apagado da folha "Compartilhar".
- `<público>/ios/`: 1320×2868 (iPhone 6,9"). `<público>/play/`: 1080×1920 (Google Play).
- Refazer: `node ../app-store/tools/moldura.mjs cru/<público> <público>/<loja> <ios|play> legendas-<público>.json`
  (precisa do `playwright-core`, que está instalado em `promocao-na-mao-dados/divulgacao/`).
