# Basis-Klasse für alle SQLAlchemy-Modelle.
# Alle Tabellen-Klassen erben von Base – dadurch kennt Alembic sie automatisch
# und kann Migrationen daraus generieren.
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass
