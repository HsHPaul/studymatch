# Schemas für Lerntreffen (erstellen und abfragen).
# raum_id ist optional – ein Treffen kann auch ohne festen Raum geplant werden.
from uuid import UUID
from datetime import date, time
from pydantic import BaseModel


class StudySessionCreate(BaseModel):
    match_id: UUID
    datum: date
    uhrzeit: time
    raum_id: UUID | None = None


class StudySessionResponse(BaseModel):
    id: UUID
    match_id: UUID
    datum: date
    uhrzeit: time
    status: str
    raum_id: UUID | None

    model_config = {"from_attributes": True}
