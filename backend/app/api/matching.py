# Liefert passende Lernpartner für den eingeloggten Nutzer.
# Die eigentliche Logik liegt im matching_service – dieser Router
# delegiert nur und gibt das Ergebnis zurück.
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.schemas.matching import MatchResponse
from app.services.matching_service import find_matches

router = APIRouter(prefix="/matches", tags=["matching"])


@router.get("", response_model=list[MatchResponse])
def get_matches(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return find_matches(current_user, db)
