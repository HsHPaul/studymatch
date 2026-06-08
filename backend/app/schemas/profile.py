# Schemas für Profil, Fächer und Zeitfenster.
from uuid import UUID
from datetime import time
from pydantic import BaseModel, Field, field_validator

from app.models.enums import Lernstil, Wochentag
from app.schemas.base import OrmBase


class SubjectResponse(OrmBase):
    id: UUID
    name: str
    kuerzel: str | None = None


class SubjectAdd(BaseModel):
    subject_id: UUID


class AvailabilityCreate(BaseModel):
    wochentag: Wochentag
    start_time: time
    end_time: time

    @field_validator("end_time")
    @classmethod
    def end_after_start(cls, v: time, info) -> time:
        start = info.data.get("start_time")
        if start is not None and v <= start:
            raise ValueError("end_time muss nach start_time liegen")
        return v


class AvailabilityResponse(OrmBase):
    id: UUID
    wochentag: Wochentag
    start_time: time
    end_time: time


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8)


class ProfileUpdate(BaseModel):
    alias: str | None = Field(default=None, min_length=2, max_length=50)
    studiengang: str | None = None
    lernstil: Lernstil | None = None
    bio: str | None = Field(default=None, max_length=500)
    min_match_score: float | None = Field(default=None, ge=0.0, le=1.0)


class ProfileResponse(OrmBase):
    id: UUID
    alias: str
    email: str
    studiengang: str | None
    lernstil: Lernstil | None
    bio: str | None
    min_match_score: float = 0.0
