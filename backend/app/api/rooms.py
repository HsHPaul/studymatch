# Campusräume für Raumvorschläge bei der Terminplanung.
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.models.room import Room
from app.schemas.room import RoomResponse

router = APIRouter(prefix="/rooms", tags=["rooms"])


@router.get("", response_model=list[RoomResponse])
def list_rooms(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(Room).all()
