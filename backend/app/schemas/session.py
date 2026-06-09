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
    uhrzeit_ende: time | None = None
    raum_id: UUID | None = None


class SessionEditPropose(BaseModel):
    datum: date
    uhrzeit: time
    uhrzeit_ende: time | None = None
    raum_id: UUID | None = None


class SessionCancel(BaseModel):
    reason: str | None = None


class StudySessionResponse(OrmBase):
    id: UUID
    match_id: UUID
    datum: date
    uhrzeit: time
    uhrzeit_ende: time | None
    status: SessionStatus
    raum_id: UUID | None
    partner_alias: str
    created_by_id: UUID | None
    proposed_datum: date | None
    proposed_uhrzeit: time | None
    proposed_uhrzeit_ende: time | None
    proposed_raum_id: UUID | None
    edit_proposed_by_id: UUID | None
    i_proposed_edit: bool
