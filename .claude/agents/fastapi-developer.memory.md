# FastAPI Developer Memory — dBLog

## Aprendizajes
- [2026-03-31] SQLAlchemy 2.0 con mapped_column, Mapped, DeclarativeBase
- [2026-03-31] TimestampMixin en base.py con id UUID, created_at, updated_at
- [2026-03-31] firebase-admin==6.6.0 para verificar tokens, inicializar sin service account JSON
- [2026-03-31] Dependency get_current_user hace upsert por firebase_uid
- [2026-03-31] Pydantic Settings para config, lee DATABASE_URL del .env

## Patrones del proyecto
- Estructura: routers/, models/, schemas/, services/, dependencies.py
- Modelos: User, Recording, NoiseRegulation con TimestampMixin
- Schemas: Create, Update, Response por cada modelo
- Routers: health, auth, users, regulations, recordings, reports
- Docker Compose con PostgreSQL 16 Alpine

## Errores a evitar
- Siempre incluir nuevos routers en main.py
- No hardcodear credenciales, usar .env.example como referencia
- Agregar nuevas dependencias a requirements.txt
- python-multipart necesario para endpoints con UploadFile
- boto3 para S3/R2 compatible storage, usar presigned URLs para descargas
- WeasyPrint + Jinja2 para generar PDFs desde templates HTML
- matplotlib para gráficas embebidas en PDF como base64
- python-multipart necesario para UploadFile en endpoints
- cryptography (Fernet) para cifrado AES de archivos en R2
- Dockerfile multi-stage con python:3.11-slim + deps de weasyprint
- Nginx como reverse proxy con Certbot para SSL
- pytest + conftest con SQLite en memoria para tests API
