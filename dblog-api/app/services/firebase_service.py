import logging

import firebase_admin
from firebase_admin import auth, credentials

from app.config import settings

logger = logging.getLogger(__name__)


class FirebaseService:
    """Servicio para inicializar Firebase Admin SDK y verificar tokens."""

    _initialized: bool = False

    @classmethod
    def initialize(cls) -> None:
        """Inicializa Firebase Admin SDK con el project_id configurado."""
        if cls._initialized:
            return
        try:
            firebase_admin.initialize_app(
                credential=None,
                options={"projectId": settings.FIREBASE_PROJECT_ID},
            )
            cls._initialized = True
            logger.info("Firebase Admin SDK inicializado correctamente")
        except Exception as e:
            logger.error("Error al inicializar Firebase Admin SDK: %s", e)
            raise

    @classmethod
    def verify_token(cls, token: str) -> dict:
        """Verifica un ID token de Firebase y retorna los claims decodificados.

        Returns:
            dict con uid, email, name, picture, etc.
        """
        if not cls._initialized:
            cls.initialize()

        decoded_token = auth.verify_id_token(token)
        return {
            "uid": decoded_token["uid"],
            "email": decoded_token.get("email"),
            "name": decoded_token.get("name"),
            "picture": decoded_token.get("picture"),
            "email_verified": decoded_token.get("email_verified", False),
        }


firebase_service = FirebaseService()
