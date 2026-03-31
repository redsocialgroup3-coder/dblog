from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    DATABASE_URL: str = "postgresql://dblog:dblog@localhost:5432/dblog"
    APP_NAME: str = "dBLog API"
    DEBUG: bool = False
    FIREBASE_PROJECT_ID: str = "your-project-id"
    R2_ENDPOINT: str = ""
    R2_ACCESS_KEY_ID: str = ""
    R2_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = "dblog-recordings"


settings = Settings()
