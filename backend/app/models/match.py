# Repräsentiert ein Matching zwischen zwei Nutzern.
# Speichert den berechneten Score und den Status (vorgeschlagen/akzeptiert/abgelehnt).
# Dient als Anker für Chat-Nachrichten und Lerntreffen.
import uuid
from datetime import datetime
from sqlalchemy import Column, Float, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Match(Base):
    __tablename__ = "matches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_a_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    user_b_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    score = Column(Float, default=0.0)
    status = Column(
        Enum("vorgeschlagen", "akzeptiert", "abgelehnt", name="match_status_enum"),
        default="vorgeschlagen",
    )
    created_at = Column(DateTime, default=datetime.utcnow)

    messages = relationship("Message", back_populates="match", cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="match", cascade="all, delete-orphan")
