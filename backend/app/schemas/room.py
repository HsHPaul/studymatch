# Schema für Raumvorschläge.
from uuid import UUID
from app.schemas.base import OrmBase


class RoomResponse(OrmBase):
    id: UUID
    gebaeude: str | None
    raumname: str
    kapazitaet: int | None
