# Geplantes Lerntreffen zwischen zwei gematchten Nutzern.
from uuid import uuid4
from datetime import datetime, timezone
from sqlalchemy import Column, Date, Time, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base
from app.models.enums import SessionStatus


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    raum_id = Column(UUID(as_uuid=True), ForeignKey("rooms.id"), nullable=True)
    datum = Column(Date, nullable=False)
    uhrzeit = Column(Time, nullable=False)
    status = Column(Enum(SessionStatus, name="session_status_enum", create_type=False), default=SessionStatus.angefragt)
    created_by_id = Column(UUID(as_uuid=True), nullable=True)
    proposed_datum = Column(Date, nullable=True)
    proposed_uhrzeit = Column(Time, nullable=True)
    proposed_raum_id = Column(UUID(as_uuid=True), nullable=True)
    edit_proposed_by_id = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    match = relationship("Match", back_populates="study_sessions")
    room = relationship("Room", back_populates="study_sessions")
