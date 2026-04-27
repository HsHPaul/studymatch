# Datenbankmodell für einen Nutzer.
from uuid import uuid4
from sqlalchemy import Column, String, Text, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base
from app.models.enums import Lernstil


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    alias = Column(String(50), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    studiengang = Column(String(100))
    lernstil = Column(Enum(Lernstil, name="lernstil_enum", create_type=False))
    bio = Column(Text)

    subjects = relationship("UserSubject", back_populates="user", cascade="all, delete-orphan")
    availabilities = relationship("Availability", back_populates="user", cascade="all, delete-orphan")
