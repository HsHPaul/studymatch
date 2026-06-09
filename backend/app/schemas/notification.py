from uuid import UUID
from datetime import datetime
from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: UUID
    title: str
    body: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}
