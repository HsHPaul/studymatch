# Schemas für Lerntreffen.
from uuid import UUID
from datetime import date, time
from pydantic import BaseModel

from app.models.enums import SessionStatus
from app.schemas.base import OrmBase


class StudySessionCreate(BaseModel):
    match_id: UUID
    datum: date
    uhrzeit: time
    raum_id: UUID | None = None


class StudySessionResponse(OrmBase):
    id: UUID
    match_id: UUID
    datum: date
    uhrzeit: time
    status: SessionStatus
    raum_id: UUID | None
