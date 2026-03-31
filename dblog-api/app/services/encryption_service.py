"""Servicio de cifrado AES-256 para archivos de audio.

Usa Fernet (AES-128-CBC) de cryptography para cifrar/descifrar archivos.
Cada usuario tiene su propia clave, cifrada con la master key del servidor.
"""

import logging
import os

from cryptography.fernet import Fernet

from app.config import settings

logger = logging.getLogger(__name__)


class EncryptionService:
    """Cifrado y descifrado de archivos y claves de usuario."""

    def __init__(self) -> None:
        self._master_fernet = Fernet(settings.ENCRYPTION_MASTER_KEY.encode())

    def generate_user_key(self) -> str:
        """Genera una nueva clave Fernet para un usuario.

        Retorna la clave ya cifrada con la master key (para almacenar en DB).
        """
        raw_key = Fernet.generate_key()
        encrypted_key = self._master_fernet.encrypt(raw_key)
        return encrypted_key.decode()

    def decrypt_user_key(self, encrypted_key: str) -> bytes:
        """Descifra la clave del usuario usando la master key."""
        return self._master_fernet.decrypt(encrypted_key.encode())

    def encrypt_file(self, file_bytes: bytes, user_key: bytes) -> bytes:
        """Cifra un archivo con la clave del usuario."""
        f = Fernet(user_key)
        return f.encrypt(file_bytes)

    def decrypt_file(self, encrypted_bytes: bytes, user_key: bytes) -> bytes:
        """Descifra un archivo con la clave del usuario."""
        f = Fernet(user_key)
        return f.decrypt(encrypted_bytes)


encryption_service = EncryptionService()
