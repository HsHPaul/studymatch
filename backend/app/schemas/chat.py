# Schemas für Chat-Nachrichten.
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from app.schemas.base import OrmBase


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class MessageResponse(OrmBase):
    id: UUID
    sender_id: UUID
    content: str
    sent_at: datetime
