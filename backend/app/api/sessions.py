# Lerntreffen planen und abfragen.
# GET /sessions gibt nur Treffen zurück an denen der eingeloggte Nutzer beteiligt ist
# (über seine Matches ermittelt).
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.user import User
from app.models.match import Match
from app.models.study_session import StudySession
from app.schemas.session import StudySessionCreate, StudySessionResponse

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
def create_session(
    payload: StudySessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = StudySession(**payload.model_dump())
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


@router.get("", response_model=list[StudySessionResponse])
def get_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    my_match_ids = db.query(Match.id).filter(
        (Match.user_a_id == current_user.id) | (Match.user_b_id == current_user.id)
    )
    return db.query(StudySession).filter(StudySession.match_id.in_(my_match_ids)).all()
