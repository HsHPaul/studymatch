# Zeitfenster eines Nutzers. Wird im Matching genutzt um überlappende Zeiten zu finden.
from uuid import uuid4
from sqlalchemy import Column, Time, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base
from app.models.enums import Wochentag


class Availability(Base):
    __tablename__ = "availabilities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    wochentag = Column(Enum(Wochentag, name="wochentag_enum", create_type=False), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    user = relationship("User", back_populates="availabilities")
