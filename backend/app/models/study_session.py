# Ein geplantes Lerntreffen zwischen zwei gematchten Nutzern.
# Verknüpft ein Match mit einem Raum, Datum und Uhrzeit.
# Status zeigt ob das Treffen noch geplant, bestätigt oder abgesagt ist.
import uuid
from datetime import datetime
from sqlalchemy import Column, Date, Time, Enum, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    match_id = Column(UUID(as_uuid=True), ForeignKey("matches.id"), nullable=False)
    raum_id = Column(UUID(as_uuid=True), ForeignKey("rooms.id"), nullable=True)
    datum = Column(Date, nullable=False)
    uhrzeit = Column(Time, nullable=False)
    status = Column(
        Enum("geplant", "bestaetigt", "abgesagt", name="session_status_enum"),
        default="geplant",
    )
    created_at = Column(DateTime, default=datetime.utcnow)

    match = relationship("Match", back_populates="study_sessions")
    room = relationship("Room", back_populates="study_sessions")
