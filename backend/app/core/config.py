# Liest alle Konfigurationswerte aus der .env-Datei.
# Zentraler Ort für Einstellungen – kein hardcodiertes Passwort oder Secret irgendwo im Code.
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    model_config = {"env_file": ".env"}


settings = Settings()
