# dBLog API - FastAPI

Backend API para dBLog.

## Comandos

```bash
python -m venv venv && source venv/bin/activate   # Crear y activar venv
pip install -r requirements.txt                     # Instalar dependencias
uvicorn app.main:app --reload                       # Ejecutar servidor dev
alembic upgrade head                                # Ejecutar migraciones
alembic revision --autogenerate -m "descripcion"    # Crear migración
```

## GitHub

**IMPORTANTE**: Este repo pertenece al usuario `redsocialgroup3-coder`.
Para comandos `gh`, usar siempre:
```bash
DBLOG_GH_TOKEN=$(git -C .. remote get-url origin | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
GH_TOKEN=$DBLOG_GH_TOKEN gh <comando>
```
**NUNCA** usar otro usuario ni el `gh auth` global.

## Stack

- FastAPI (Python)
- PostgreSQL (SQLAlchemy + Alembic)
- Cloudflare R2 (almacenamiento de audio)
- WeasyPrint (generación de PDF)
- Firebase Auth (verificación de tokens)
