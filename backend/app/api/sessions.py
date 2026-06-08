from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.api.deps import get_current_user, get_match_for_user
from app.core.database import get_db
from app.models.enums import MatchStatus, SessionStatus
from app.models.user import User
from app.models.match import Match
from app.models.study_session import StudySession
from app.schemas.session import StudySessionCreate, SessionEditPropose, StudySessionResponse

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _with_partner(session: StudySession, current_user_id: UUID, db: Session) -> dict:
    match = session.match or db.query(Match).filter(Match.id == session.match_id).first()
    partner_id = match.user_b_id if match.user_a_id == current_user_id else match.user_a_id
    partner = db.query(User).filter(User.id == partner_id).first()
    return {
        'id': session.id,
        'match_id': session.match_id,
        'datum': session.datum,
        'uhrzeit': session.uhrzeit,
        'status': session.status,
        'raum_id': session.raum_id,
        'partner_alias': partner.alias if partner else 'Unbekannt',
        'created_by_id': session.created_by_id,
        'proposed_datum': session.proposed_datum,
        'proposed_uhrzeit': session.proposed_uhrzeit,
        'proposed_raum_id': session.proposed_raum_id,
        'edit_proposed_by_id': session.edit_proposed_by_id,
        'i_proposed_edit': session.edit_proposed_by_id == current_user_id,
    }


def _get_my_session(session_id: UUID, current_user: User, db: Session) -> StudySession:
    session = db.query(StudySession).filter(StudySession.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Termin nicht gefunden")
    get_match_for_user(session.match_id, current_user, db)
    return session


@router.post("", response_model=StudySessionResponse, status_code=status.HTTP_201_CREATED)
def create_session(
    payload: StudySessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    match = get_match_for_user(payload.match_id, current_user, db)
    if match.status != MatchStatus.akzeptiert:
        raise HTTPException(status_code=403, detail="Termin nur bei bestätigtem Match möglich")
    session = StudySession(
        **payload.model_dump(),
        created_by_id=current_user.id,
        status=SessionStatus.angefragt,
    )
    db.add(session)
    db.commit()
    db.refresh(session)
    return _with_partner(session, current_user.id, db)


@router.get("", response_model=list[StudySessionResponse])
def get_sessions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    my_match_ids = db.query(Match.id).filter(
        (Match.user_a_id == current_user.id) | (Match.user_b_id == current_user.id)
    )
    sessions = (
        db.query(StudySession)
        .filter(
            StudySession.match_id.in_(my_match_ids),
            StudySession.status.in_([SessionStatus.geplant, SessionStatus.bestaetigt]),
        )
        .options(joinedload(StudySession.match))
        .all()
    )
    return [_with_partner(s, current_user.id, db) for s in sessions]


@router.get("/pending/{match_id}", response_model=list[StudySessionResponse])
def get_pending_sessions(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_match_for_user(match_id, current_user, db)
    sessions = (
        db.query(StudySession)
        .filter(
            StudySession.match_id == match_id,
            StudySession.status == SessionStatus.angefragt,
            StudySession.created_by_id != current_user.id,
        )
        .options(joinedload(StudySession.match))
        .all()
    )
    return [_with_partner(s, current_user.id, db) for s in sessions]


@router.post("/{session_id}/accept", status_code=status.HTTP_204_NO_CONTENT)
def accept_session(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = _get_my_session(session_id, current_user, db)
    if session.status != SessionStatus.angefragt:
        raise HTTPException(status_code=400, detail="Keine offene Anfrage")
    if session.created_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Anfrage nicht bestätigen")
    session.status = SessionStatus.geplant
    db.commit()


@router.post("/{session_id}/decline", status_code=status.HTTP_204_NO_CONTENT)
def decline_session(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = _get_my_session(session_id, current_user, db)
    if session.status != SessionStatus.angefragt:
        raise HTTPException(status_code=400, detail="Keine offene Anfrage")
    if session.created_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Anfrage nicht ablehnen")
    session.status = SessionStatus.abgesagt
    db.commit()


@router.patch("/{session_id}/propose-edit", response_model=StudySessionResponse)
def propose_edit(
    session_id: UUID,
    payload: SessionEditPropose,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = _get_my_session(session_id, current_user, db)
    if session.status not in (SessionStatus.geplant, SessionStatus.bestaetigt):
        raise HTTPException(status_code=400, detail="Nur bestätigte Termine können bearbeitet werden")
    if session.edit_proposed_by_id is not None:
        raise HTTPException(status_code=400, detail="Es gibt bereits eine offene Änderungsanfrage")
    session.proposed_datum = payload.datum
    session.proposed_uhrzeit = payload.uhrzeit
    session.proposed_raum_id = payload.raum_id
    session.edit_proposed_by_id = current_user.id
    db.commit()
    db.refresh(session)
    return _with_partner(session, current_user.id, db)


@router.post("/{session_id}/accept-edit", response_model=StudySessionResponse)
def accept_edit(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = _get_my_session(session_id, current_user, db)
    if session.edit_proposed_by_id is None:
        raise HTTPException(status_code=400, detail="Keine offene Änderungsanfrage")
    if session.edit_proposed_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Änderung nicht bestätigen")
    session.datum = session.proposed_datum
    session.uhrzeit = session.proposed_uhrzeit
    session.raum_id = session.proposed_raum_id
    session.proposed_datum = None
    session.proposed_uhrzeit = None
    session.proposed_raum_id = None
    session.edit_proposed_by_id = None
    db.commit()
    db.refresh(session)
    return _with_partner(session, current_user.id, db)


@router.post("/{session_id}/decline-edit", status_code=status.HTTP_204_NO_CONTENT)
def decline_edit(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = _get_my_session(session_id, current_user, db)
    if session.edit_proposed_by_id is None:
        raise HTTPException(status_code=400, detail="Keine offene Änderungsanfrage")
    if session.edit_proposed_by_id == current_user.id:
        raise HTTPException(status_code=400, detail="Du kannst deine eigene Änderung nicht ablehnen")
    session.proposed_datum = None
    session.proposed_uhrzeit = None
    session.proposed_raum_id = None
    session.edit_proposed_by_id = None
    db.commit()
