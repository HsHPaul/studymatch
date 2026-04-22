# Einstiegspunkt der FastAPI-Anwendung.
# Registriert alle Router und globale Middleware (CORS erlaubt Anfragen vom Flutter-Frontend).
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import auth, profiles, matching, chat, sessions, rooms

app = FastAPI(title="StudyMatch API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
    return {"status": "ok"}
