import logging

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.services.firebase_service import firebase_service

logger = logging.getLogger(__name__)

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """Dependency que verifica el token de Firebase y retorna el usuario.

    - Lee el header Authorization: Bearer <token>
    - Verifica con FirebaseService
    - Busca/crea usuario en DB (upsert por firebase_uid)
    - Retorna el modelo User
    - Raise HTTPException 401 si token inválido
    """
    token = credentials.credentials

    try:
        firebase_data = firebase_service.verify_token(token)
    except Exception as e:
        logger.warning("Token inválido: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Firebase inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Upsert: buscar por firebase_uid o crear
    user = db.query(User).filter(User.firebase_uid == firebase_data["uid"]).first()

    if user is None:
        user = User(
            firebase_uid=firebase_data["uid"],
            email=firebase_data["email"] or "",
            display_name=firebase_data.get("name"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info("Nuevo usuario creado: %s", user.firebase_uid)
    else:
        # Actualizar email y display_name si cambiaron
        updated = False
        if firebase_data["email"] and user.email != firebase_data["email"]:
            user.email = firebase_data["email"]
            updated = True
        if firebase_data.get("name") and user.display_name != firebase_data["name"]:
            user.display_name = firebase_data["name"]
            updated = True
        if updated:
            db.commit()
            db.refresh(user)

    return user
