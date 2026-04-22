# Campusräume abfragen für Raumvorschläge bei der Terminplanung.
# Im MVP werden Räume manuell in die DB eingepflegt (keine externe API).
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.services.room_service import get_available_rooms

router = APIRouter(prefix="/rooms", tags=["rooms"])


@router.get("")
def list_rooms(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_available_rooms(db)
