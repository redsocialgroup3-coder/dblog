import logging
from typing import BinaryIO

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

from app.config import settings

logger = logging.getLogger(__name__)


class StorageService:
    """Servicio de almacenamiento compatible con S3/Cloudflare R2."""

    def __init__(self) -> None:
        self._client = boto3.client(
            "s3",
            endpoint_url=settings.R2_ENDPOINT,
            aws_access_key_id=settings.R2_ACCESS_KEY_ID,
            aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
            config=Config(signature_version="s3v4"),
            region_name="auto",
        )
        self._bucket = settings.R2_BUCKET_NAME

    def upload_file(self, file: BinaryIO, key: str, content_type: str = "audio/mp4") -> str:
        """Sube un archivo a R2 y retorna la URL pública."""
        self._client.upload_fileobj(
            file,
            self._bucket,
            key,
            ExtraArgs={"ContentType": content_type},
        )
        url = f"{settings.R2_ENDPOINT}/{self._bucket}/{key}"
        logger.info("Archivo subido: %s", key)
        return url

    def download_url(self, key: str, expires_in: int = 3600) -> str:
        """Genera una URL presigned para descargar un archivo."""
        url = self._client.generate_presigned_url(
            "get_object",
            Params={"Bucket": self._bucket, "Key": key},
            ExpiresIn=expires_in,
        )
        return url

    def delete_file(self, key: str) -> None:
        """Elimina un archivo de R2."""
        try:
            self._client.delete_object(Bucket=self._bucket, Key=key)
            logger.info("Archivo eliminado: %s", key)
        except ClientError as e:
            logger.error("Error eliminando %s: %s", key, e)
            raise


storage_service = StorageService()
