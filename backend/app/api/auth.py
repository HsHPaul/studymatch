# Registrierung und Login.
# Register legt einen neuen Nutzer an und gibt sofort einen Token zurück.
# Login prüft E-Mail + Passwort und gibt bei Erfolg einen Token zurück.
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.core.limiter import limiter
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginRequest, Token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
def register(request: Request, payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == payload.email).first():
        raise HTTPException(status_code=400, detail="Registrierung nicht möglich")
    user = User(
        alias=payload.alias,
        email=payload.email,
        hashed_password=hash_password(payload.password),
        studiengang=payload.studiengang,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return Token(access_token=create_access_token(str(user.id)))


@router.post("/login", response_model=Token)
@limiter.limit("5/minute")
def login(request: Request, payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Ungültige Anmeldedaten")
    return Token(access_token=create_access_token(str(user.id)))
