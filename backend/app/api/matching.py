from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.enums import MatchStatus
from app.models.match import Match
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


def _get_my_match(match_id: UUID, current_user: User, db: Session) -> Match:
    match = db.query(Match).filter(
        Match.id == match_id,
        (Match.user_a_id == current_user.id) | (Match.user_b_id == current_user.id),
    ).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match nicht gefunden")
    return match


@router.post("/{match_id}/request", status_code=status.HTTP_204_NO_CONTENT)
def send_request(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    match = _get_my_match(match_id, current_user, db)
    if match.status != MatchStatus.vorgeschlagen:
        raise HTTPException(status_code=400, detail="Anfrage bereits gesendet oder Match bereits bestätigt")
    match.status = MatchStatus.angefragt
    match.requested_by_id = current_user.id
    db.commit()


@router.post("/{match_id}/accept", status_code=status.HTTP_204_NO_CONTENT)
def accept_request(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    match = _get_my_match(match_id, current_user, db)
    if match.status != MatchStatus.angefragt:
        raise HTTPException(status_code=400, detail="Keine offene Anfrage für dieses Match")
    if match.requested_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Anfrage nicht bestätigen")
    match.status = MatchStatus.akzeptiert
    db.commit()


@router.post("/{match_id}/decline", status_code=status.HTTP_204_NO_CONTENT)
def decline_request(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    match = _get_my_match(match_id, current_user, db)
    if match.status != MatchStatus.angefragt:
        raise HTTPException(status_code=400, detail="Keine offene Anfrage für dieses Match")
    if match.requested_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Anfrage nicht ablehnen")
    match.status = MatchStatus.abgelehnt
    db.commit()
