# Schemas für Chat-Nachrichten (senden und empfangen).
# MessageResponse gibt immer Absender-ID und Zeitstempel zurück,
# damit die App Nachrichten korrekt anzeigen kann.
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel


class MessageCreate(BaseModel):
    content: str


class MessageResponse(BaseModel):
    id: UUID
    sender_id: UUID
    content: str
    sent_at: datetime

    model_config = {"from_attributes": True}
