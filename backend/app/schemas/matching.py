# Schema für Matching-Ergebnisse.
from uuid import UUID
from datetime import time
from pydantic import BaseModel

from app.models.enums import Lernstil, MatchStatus


class AvailabilityOverlap(BaseModel):
    wochentag: str
    start_time: time
    end_time: time


class MatchResponse(BaseModel):
    match_id: UUID
    user_id: UUID
    alias: str
    studiengang: str | None
    lernstil: Lernstil | None
    gemeinsame_faecher: list[str]
    ueberschneidungen: list[AvailabilityOverlap]
    score: float
    status: MatchStatus
    i_requested: bool
