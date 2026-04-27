# Wiederverwendbare Dependencies: eingeloggter User und Match-Zugriffsprüfung.
# Eager loading der User-Relationships hier verhindert N+1-Queries in allen Endpoints.
from uuid import UUID
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session, selectinload

from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User
from app.models.subject import UserSubject
from app.models.match import Match

bearer = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    user_id = decode_token(credentials.credentials)
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Ungültiger Token")
    user = (
        db.query(User)
        .options(
            selectinload(User.subjects).selectinload(UserSubject.subject),
            selectinload(User.availabilities),
        )
        .filter(User.id == user_id)
        .first()
    )
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nutzer nicht gefunden")
    return user


def get_match_for_user(match_id: UUID, current_user: User, db: Session) -> Match:
    # Stellt sicher dass der eingeloggte Nutzer Teilnehmer des Matches ist.
    match = db.query(Match).filter(
        Match.id == match_id,
        (Match.user_a_id == current_user.id) | (Match.user_b_id == current_user.id),
    ).first()
    if not match:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Kein Zugriff auf dieses Match")
    return match
