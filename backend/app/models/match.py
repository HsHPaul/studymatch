# Matching zwischen zwei Nutzern mit Score und Status.
from uuid import uuid4
from datetime import datetime, timezone
from sqlalchemy import Column, Float, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base
from app.models.enums import MatchStatus


class Match(Base):
    __tablename__ = "matches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_a_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    user_b_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    score = Column(Float, default=0.0)
    status = Column(Enum(MatchStatus, name="match_status_enum", create_type=False), default=MatchStatus.vorgeschlagen)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    messages = relationship("Message", back_populates="match", cascade="all, delete-orphan")
    study_sessions = relationship("StudySession", back_populates="match", cascade="all, delete-orphan")
