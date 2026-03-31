from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    DATABASE_URL: str = "postgresql://dblog:dblog@localhost:5432/dblog"
    APP_NAME: str = "dBLog API"
    DEBUG: bool = False


settings = Settings()
