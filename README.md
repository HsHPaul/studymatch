# StudyMatch

Mobile App zur Vermittlung von Lernpartnern und Lernräumen auf dem Campus.  
Studierende legen ein Profil an, geben Fach, Lernstil und Verfügbarkeit an und erhalten passende Lernpartner-Vorschläge. Über einen integrierten Chat können Termine abgestimmt und Campusräume gefunden werden.

**Status:** MVP in Entwicklung | Uni-Projekt | 8-Wochen-Sprint

---

## Für KI-Assistenten (Claude, Claude Code, ChatGPT)

Dieses Projekt ist eine mobile App mit folgendem Stack:

- **Frontend:** Flutter (Dart) — noch nicht implementiert
- **Backend:** Python 3.11+, FastAPI — vollständig als Grundgerüst vorhanden
- **Datenbank:** PostgreSQL via SQLAlchemy + Alembic
- **Auth:** JWT (python-jose + passlib/bcrypt)
- **Chat:** WebSockets (FastAPI), REST-Fallback vorhanden
- **Projektmanagement:** Jira + GitLab (GWDG)

### Architektur (Backend)
```
backend/
├── app/
│   ├── api/         → Route-Handler (auth, profiles, matching, chat, sessions, rooms)
│   ├── core/        → Config (.env), DB-Connection, Security (JWT, Hashing)
│   ├── models/      → SQLAlchemy ORM-Modelle (8 Tabellen)
│   ├── schemas/     → Pydantic Request/Response-Schemas
│   └── services/    → Business-Logik (Matching-Algorithmus, Rooms)
├── alembic/         → DB-Migrationen
└── main.py          → FastAPI-App, Router-Registrierung, CORS
```

### Matching-Algorithmus
Regelbasiert (kein ML). Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit.  
Scoring: Fach 40% | Lernstil 25% | Zeitüberlappung 20% | Studiengang 10%

### Was noch fehlt (nächste Sprints)
- Flutter-Frontend (features: auth, profile, matching, chat, sessions)
- WebSocket-Connection-Manager für Echtzeit-Chat
- Seed-Daten für Fächer und Räume
- Tests (pytest)
- GitLab CI/CD Pipeline

### Wichtige Konventionen
- Code-Sprache: Englisch (Variablen, Funktionen, Commits)
- Kommunikation im Team: Deutsch
- Branch-Namen: `feature/SM-<jira-ticket>-kurzbeschreibung`
- Commit-Format: `SM-<nr>: Kurzbeschreibung`
- Keine Business-Logik in Route-Handlern — immer in `services/`
- DB-Änderungen immer über Alembic-Migration, nie direkt

---

## Für Menschen (Quickstart)

### Voraussetzungen
- Python 3.11+
- Docker Desktop

### Backend starten

```bash
cd backend

# 1. Umgebungsvariablen anlegen
cp .env.example .env

# 2. Datenbank starten (PostgreSQL via Docker)
docker compose up -d

# 3. Python-Umgebung einrichten
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 4. Datenbankschema anlegen
alembic upgrade head

# 5. Server starten
uvicorn app.main:app --reload
```

API läuft unter: `http://localhost:8000`  
Interaktive Dokumentation: `http://localhost:8000/docs`

### Umgebungsvariablen (`.env`)

| Variable | Beschreibung | Beispiel |
|---|---|---|
| `DATABASE_URL` | PostgreSQL-Verbindung | `postgresql://user:pw@localhost:5432/studymatch` |
| `SECRET_KEY` | JWT-Signing-Key (langer Zufallsstring) | `supersecretkey123...` |
| `ALGORITHM` | JWT-Algorithmus | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token-Gültigkeit | `30` |

### API-Endpunkte (Überblick)

| Methode | Pfad | Beschreibung |
|---|---|---|
| POST | `/api/v1/auth/register` | Neuen Account anlegen |
| POST | `/api/v1/auth/login` | Login → JWT-Token |
| GET | `/api/v1/profiles/me` | Eigenes Profil abrufen |
| PATCH | `/api/v1/profiles/me` | Profil bearbeiten |
| POST | `/api/v1/profiles/me/subjects` | Fach hinzufügen |
| DELETE | `/api/v1/profiles/me/subjects/{id}` | Fach entfernen |
| POST | `/api/v1/profiles/me/availabilities` | Zeitfenster hinzufügen |
| DELETE | `/api/v1/profiles/me/availabilities/{id}` | Zeitfenster entfernen |
| GET | `/api/v1/matches` | Passende Lernpartner abrufen |
| GET | `/api/v1/chat/{match_id}/messages` | Chatverlauf laden |
| POST | `/api/v1/chat/{match_id}/messages` | Nachricht senden |
| WS | `/api/v1/chat/ws/{match_id}` | Echtzeit-Chat (Sprint 2) |
| POST | `/api/v1/sessions` | Lerntreffen anlegen |
| GET | `/api/v1/sessions` | Eigene Lerntreffen abrufen |
| GET | `/api/v1/rooms` | Verfügbare Räume abrufen |
| GET | `/health` | Server-Status |

### Nützliche Befehle

```bash
# Neue DB-Migration generieren (nach Modelländerung)
alembic revision --autogenerate -m "beschreibung"

# Migration ausführen
alembic upgrade head

# Migration rückgängig machen
alembic downgrade -1

# Tests ausführen
pytest

# Datenbank zurücksetzen (Vorsicht!)
docker compose down -v && docker compose up -d && alembic upgrade head
```

---

## Datenmodell

```
users ──────< user_subjects >────── subjects
  │                                  (Fächer/Module)
  └──< availabilities
         (Zeitfenster pro Wochentag)

matches ──────< messages
   │             (Chat-Nachrichten)
   └──────< study_sessions >────── rooms
              (Lerntreffen)          (Campusräume)
```

---

## MVP-Scope

**Enthalten:** Registrierung, Profil, Fächer, Lernstil, Zeitfenster, Matching, Chat, Terminvereinbarung, Raumvorschläge  
**Nicht im MVP:** Video-Call, Kalender-Sync, Hochschul-SSO, Gruppen-Algorithmen, Gamification

---

## Team

Uni-Projekt — Backend-Entwicklung mit FastAPI + PostgreSQL, Frontend mit Flutter.  
Projektmanagement via Jira, Versionskontrolle via GitLab (GWDG).
