# Datenbankmodell für einen Nutzer.
# Speichert Login-Daten (Email, Passwort-Hash) und Profil-Infos (Alias, Studiengang, Lernstil).
# Verknüpft über Relationships direkt mit Fächern und Zeitfenstern.
import uuid
from sqlalchemy import Column, String, Text, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    alias = Column(String(50), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    studiengang = Column(String(100))
    lernstil = Column(Enum("still", "gemischt", "diskutierend", name="lernstil_enum"))
    bio = Column(Text)

    subjects = relationship("UserSubject", back_populates="user", cascade="all, delete-orphan")
    availabilities = relationship("Availability", back_populates="user", cascade="all, delete-orphan")
