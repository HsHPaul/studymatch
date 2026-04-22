# Schemas für Profil-Lesen, -Bearbeiten sowie Fächer- und Zeitfenster-Verwaltung.
# Trennt was die API nach außen zeigt von dem was in der DB steht
# (z.B. kein hashed_password in ProfileResponse).
from uuid import UUID
from datetime import time
from typing import Literal
from pydantic import BaseModel


class SubjectResponse(BaseModel):
    id: UUID
    name: str
    kuerzel: str | None = None

    model_config = {"from_attributes": True}


class SubjectAdd(BaseModel):
    subject_id: UUID


class AvailabilityCreate(BaseModel):
    wochentag: Literal["montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag"]
    start_time: time
    end_time: time


class AvailabilityResponse(BaseModel):
    id: UUID
    wochentag: str
    start_time: time
    end_time: time

    model_config = {"from_attributes": True}


class ProfileUpdate(BaseModel):
    alias: str | None = None
    studiengang: str | None = None
    lernstil: Literal["still", "gemischt", "diskutierend"] | None = None
    bio: str | None = None


class ProfileResponse(BaseModel):
    id: UUID
    alias: str
    email: str
    studiengang: str | None
    lernstil: str | None
    bio: str | None

    model_config = {"from_attributes": True}
