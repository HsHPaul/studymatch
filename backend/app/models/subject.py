# Fächer/Module die an der Hochschule existieren (z.B. "Analysis", "Algorithmen").
# UserSubject ist die Verbindungstabelle zwischen User und Subject (N:M-Beziehung),
# da ein Nutzer mehrere Fächer haben kann und ein Fach von vielen Nutzern gewählt wird.
import uuid
from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Subject(Base):
    __tablename__ = "subjects"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    kuerzel = Column(String(20))

    user_subjects = relationship("UserSubject", back_populates="subject")


class UserSubject(Base):
    __tablename__ = "user_subjects"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"), primary_key=True)

    user = relationship("User", back_populates="subjects")
    subject = relationship("Subject", back_populates="user_subjects")
