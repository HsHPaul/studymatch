# Passwort-Hashing (bcrypt) und JWT-Token-Verwaltung.
# Nach dem Login bekommt der Nutzer einen Token – jede weitere Anfrage
# wird damit authentifiziert, ohne erneuten DB-Lookup des Passworts.
from datetime import datetime, timedelta
from typing import Optional

import bcrypt
from jose import JWTError, jwt

from app.core.config import settings


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


_ALGORITHM = "HS256"


def create_access_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    from datetime import timezone
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    return jwt.encode(
        {"sub": subject, "exp": expire},
        settings.secret_key,
        algorithm=_ALGORITHM,
    )


def decode_token(token: str) -> Optional[str]:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[_ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None
