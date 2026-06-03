# Einstiegspunkt der FastAPI-Anwendung.
# Registriert alle Router und globale Middleware (CORS erlaubt Anfragen vom Flutter-Frontend).
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from sqlalchemy import text

from app.api import auth, profiles, matching, chat, sessions, rooms
from app.core.config import settings
from app.core.database import SessionLocal
from app.core.limiter import limiter

app = FastAPI(title="StudyMatch API", version="0.1.0")
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    # Produktions-Origins kommen aus der ENV (CORS_ORIGINS), lokale Entwicklung
    # bleibt über den localhost-Regex immer erlaubt.
    allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(profiles.router, prefix="/api/v1")
app.include_router(matching.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
app.include_router(sessions.router, prefix="/api/v1")
app.include_router(rooms.router, prefix="/api/v1")


@app.get("/health")
def health():
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"status": "db_unavailable"},
        )
    finally:
        db.close()
