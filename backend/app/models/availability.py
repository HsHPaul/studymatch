# Zeitfenster eines Nutzers (z.B. Montag 10:00–12:00).
# Wird im Matching-Algorithmus genutzt um überlappende Zeiten zwischen zwei Nutzern zu finden.
# Ein Nutzer kann mehrere Zeitfenster pro Woche hinterlegen.
import uuid
from sqlalchemy import Column, Time, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Availability(Base):
    __tablename__ = "availabilities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    wochentag = Column(
        Enum("montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag", name="wochentag_enum"),
        nullable=False,
    )
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    user = relationship("User", back_populates="availabilities")
