# Schema für die Matching-Ergebnisse die an die App zurückgesendet werden.
# Enthält neben den Nutzerdaten auch die berechneten Überschneidungen und den Score.
from uuid import UUID
from pydantic import BaseModel


class AvailabilityOverlap(BaseModel):
    wochentag: str
    start_time: str
    end_time: str


class MatchResponse(BaseModel):
    user_id: UUID
    alias: str
    studiengang: str | None
    lernstil: str | None
    gemeinsame_faecher: list[str]
    ueberschneidungen: list[AvailabilityOverlap]
    score: float
