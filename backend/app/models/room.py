# Lernraum auf dem Campus (Gebäude, Raumname, Kapazität).
# Im MVP werden Räume als statische Daten gepflegt (kein Echtzeit-Belegungsplan).
# Wird als Vorschlag bei der Terminplanung angezeigt.
import uuid
from sqlalchemy import Column, String, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Room(Base):
    __tablename__ = "rooms"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    gebaeude = Column(String(100))
    raumname = Column(String(50), nullable=False)
    kapazitaet = Column(Integer)

    study_sessions = relationship("StudySession", back_populates="room")
