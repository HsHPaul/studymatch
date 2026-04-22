# Baut die Verbindung zu PostgreSQL auf und stellt get_db() bereit.
# get_db() wird per Dependency Injection in jeden Route-Handler injiziert,
# der Datenbankzugriff benötigt.
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

from app.core.config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()
