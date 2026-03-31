# dBLog - Monorepo

App para medir, registrar y documentar legalmente el ruido excesivo.

## Estructura

```
dblog/
├── dblog-app/    # Flutter app (iOS + Android)
├── dblog-api/    # FastAPI backend (Python)
└── CLAUDE.md
```

## GitHub

- **Organización**: redsocialgroup3-coder
- **Repo**: https://github.com/redsocialgroup3-coder/dblog
- **IMPORTANTE**: Este repo pertenece al usuario `redsocialgroup3-coder`. 
  El token de GitHub está embebido en la URL remota del repo.
  Para comandos `gh`, extraer el token y usarlo como prefijo:
  ```bash
  DBLOG_GH_TOKEN=$(git remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
  GH_TOKEN=$DBLOG_GH_TOKEN gh <comando>
  ```
  **NUNCA** usar otro usuario ni el `gh auth` global (que es `orlando-marques`).

## Commits

Seguir Conventional Commits en español:
```
<tipo>(<scope>): <descripción>
```
Scopes: `app`, `api`, `monorepo`

## Stack

- **App**: Flutter (Dart)
- **API**: FastAPI (Python), PostgreSQL, Cloudflare R2
- **Auth**: Firebase Auth
- **Pagos**: RevenueCat
- **PDF**: WeasyPrint
