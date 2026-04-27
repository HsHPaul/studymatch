# Schema für Matching-Ergebnisse.
from uuid import UUID
from datetime import time
from pydantic import BaseModel

from app.models.enums import Lernstil


class AvailabilityOverlap(BaseModel):
    wochentag: str
    start_time: time
    end_time: time


class MatchResponse(BaseModel):
    user_id: UUID
    alias: str
    studiengang: str | None
    lernstil: Lernstil | None
    gemeinsame_faecher: list[str]
    ueberschneidungen: list[AvailabilityOverlap]
    score: float
