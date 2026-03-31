import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.user import UserResponse
from app.services.firebase_service import firebase_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


class TokenRequest(BaseModel):
    token: str


@router.post("/verify", response_model=UserResponse)
async def verify_token(body: TokenRequest, db: Session = Depends(get_db)):
    """Verifica un token de Firebase, crea/actualiza usuario en DB y retorna UserResponse."""
    try:
        firebase_data = firebase_service.verify_token(body.token)
    except Exception as e:
        logger.warning("Token inválido en /auth/verify: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de Firebase inválido o expirado",
        )

    # Upsert por firebase_uid
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
        logger.info("Usuario creado via /auth/verify: %s", user.firebase_uid)
    else:
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


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    """Retorna el usuario actual autenticado."""
    return current_user
