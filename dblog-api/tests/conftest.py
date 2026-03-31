import os
import sys
import uuid
from datetime import datetime, timezone
from types import ModuleType
from unittest.mock import MagicMock, patch

import pytest

# Configurar variables de entorno ANTES de importar app para evitar
# errores de inicializacion de servicios (S3/R2, Firebase, etc).
os.environ.setdefault("R2_ENDPOINT", "https://fake-r2.example.com")
os.environ.setdefault("R2_ACCESS_KEY_ID", "fake-key")
os.environ.setdefault("R2_SECRET_ACCESS_KEY", "fake-secret")
os.environ.setdefault("R2_BUCKET_NAME", "test-bucket")
os.environ.setdefault("FIREBASE_PROJECT_ID", "test-project")
os.environ.setdefault("DATABASE_URL", "sqlite:///test.db")

# Mock de weasyprint para evitar dependencia de libgobject nativa.
_weasyprint_mock = MagicMock()
sys.modules.setdefault("weasyprint", _weasyprint_mock)

from fastapi.testclient import TestClient
from sqlalchemy import StaticPool, create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.database import get_db
from app.main import app
from app.models.base import Base
from app.models.noise_regulation import NoiseRegulation


# -- Base de datos en memoria para tests --

SQLALCHEMY_TEST_URL = "sqlite://"

engine = create_engine(
    SQLALCHEMY_TEST_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def create_tables():
    """Crea las tablas una vez por sesion de tests."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def db_session():
    """Provee una sesion de DB limpia por test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture()
def client(db_session: Session):
    """TestClient con override de la dependencia get_db."""

    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()


@pytest.fixture()
def seed_regulations(db_session: Session):
    """Inserta regulaciones de ejemplo para tests."""
    regulations = [
        NoiseRegulation(
            id=uuid.uuid4(),
            municipality="España (Ley 37/2003)",
            zone_type="residencial",
            time_period="diurno",
            noise_type="exterior",
            db_limit=65.0,
            regulation_name="Ley 37/2003 - Real Decreto 1367/2007",
            article="Anexo II - Tabla A",
            created_at=datetime.now(timezone.utc),
        ),
        NoiseRegulation(
            id=uuid.uuid4(),
            municipality="España (Ley 37/2003)",
            zone_type="residencial",
            time_period="nocturno",
            noise_type="exterior",
            db_limit=55.0,
            regulation_name="Ley 37/2003 - Real Decreto 1367/2007",
            article="Anexo II - Tabla A",
            created_at=datetime.now(timezone.utc),
        ),
        NoiseRegulation(
            id=uuid.uuid4(),
            municipality="Madrid",
            zone_type="residencial",
            time_period="diurno",
            noise_type="exterior",
            db_limit=60.0,
            regulation_name="Ordenanza Municipal de Madrid",
            article="Art. 14",
            created_at=datetime.now(timezone.utc),
        ),
    ]
    for reg in regulations:
        db_session.add(reg)
    db_session.commit()
    return regulations
