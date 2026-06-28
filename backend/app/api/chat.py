# Chat zwischen gematchten Nutzern. Nur Teilnehmer des Matches dürfen lesen/schreiben.
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_match_for_user
from app.core.blacklist import is_chat_blocked
from app.core.database import get_db
from app.models.enums import MatchStatus
from app.models.match import Match
from app.models.user import User
from app.models.message import Message
from app.schemas.chat import LastMessageSummaryResponse, MessageCreate, MessageResponse

router = APIRouter(prefix="/chat", tags=["chat"])


@router.get("/unread", response_model=list[LastMessageSummaryResponse])
def get_unread_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    accepted = db.query(Match).filter(
        Match.status == MatchStatus.akzeptiert,
        or_(Match.user_a_id == current_user.id, Match.user_b_id == current_user.id),
    ).all()
    result = []
    for m in accepted:
        latest = (
            db.query(Message)
            .filter(Message.match_id == m.id)
            .order_by(Message.sent_at.desc())
            .first()
        )
        if latest:
            result.append({
                'match_id': m.id,
                'last_message_id': latest.id,
                'last_sender_id': latest.sender_id,
                'last_sent_at': latest.sent_at,
            })
    return result


@router.get("/{match_id}/messages", response_model=list[MessageResponse])
def get_messages(
    match_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_match_for_user(match_id, current_user, db)
    return db.query(Message).filter(Message.match_id == match_id).order_by(Message.sent_at).all()


@router.post("/{match_id}/messages", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
def send_message(
    match_id: UUID,
    payload: MessageCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_match_for_user(match_id, current_user, db)
    if is_chat_blocked(payload.content):
        raise HTTPException(status_code=400, detail="Diese Nachricht enthält unerlaubte Inhalte.")
    msg = Message(match_id=match_id, sender_id=current_user.id, content=payload.content)
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


@router.websocket("/ws/{match_id}")
async def websocket_chat(match_id: UUID, websocket: WebSocket):
    # Sprint 2: Auth via Token-Query-Parameter + Connection-Manager einbauen
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(data)
    except WebSocketDisconnect:
        pass
