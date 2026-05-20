# StudyMatch – CLAUDE.md

## Projektkontext
Mobile App zur Vermittlung von Lernpartnern und Lernräumen auf dem Campus.
Uni-Projekt, MVP in 8 Wochen, agile Entwicklung mit Jira + GitLab.

## Tech Stack
| Schicht | Technologie |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Python 3.11+, FastAPI |
| Datenbank | PostgreSQL (Supabase, Produktion) |
| ORM / Migrations | SQLAlchemy + Alembic |
| Auth | JWT (python-jose) |
| Chat | WebSockets (FastAPI native) |
| CI/CD | GitLab CI |
| Projektmanagement | Jira |

## Monorepo-Struktur
```
studymatch/                  ← GitLab-Repo-Root
├── backend/                 ← Python/FastAPI
│   ├── app/
│   │   ├── api/             # Route Handler
│   │   ├── core/            # Config, Security, DB
│   │   ├── models/          # SQLAlchemy ORM
│   │   ├── schemas/         # Pydantic Schemas
│   │   └── services/        # Business Logic
│   ├── alembic/
│   ├── tests/
│   ├── requirements.txt
│   └── docker-compose.yml
├── frontend/                ← Flutter
│   ├── lib/
│   │   ├── core/            # Theme, Router, HTTP-Client
│   │   ├── features/        # auth, profile, matching, chat, sessions
│   │   └── shared/          # Widgets, Models
│   └── pubspec.yaml
├── docs/                    ← Architektur, Use Cases, ADRs
└── CLAUDE.md
```

## Coding-Konventionen

### Backend (Python)
- Sprache im Code: Englisch (Variablen, Funktionen, Kommentare)
- Pydantic für alle Request/Response-Schemas
- SQLAlchemy 2.x (async-fähig)
- Keine Business-Logik in Route-Handlern – immer in services/
- Alle Endpunkte unter `/api/v1/`

### Frontend (Flutter/Dart)
- State Management: Riverpod
- Navigation: go_router
- HTTP-Client: Dio
- Feature-first Ordnerstruktur (nicht layer-first)
- Kein Business-Logik in Widgets – in Provider/Notifier

## Umgebung & Setup

### Datenbank (Supabase)
- Host: `db.flqhltziakhhkviyomzl.supabase.co`, Port: 5432, DB: `postgres`, User: `postgres`
- Passwort steht in `backend/.env` (gitignored – nie committen)
- `.env` Format: `DATABASE_URL=postgresql://postgres:PASSWORT@db.flqhltziakhhkviyomzl.supabase.co:5432/postgres?sslmode=require`
- Alembic liest die URL aus `settings` (via `alembic/env.py`), nicht aus `alembic.ini`
- Tabellen bereits migriert (`alembic stamp head` war nötig weil DB schon befüllt war)
- DB-Verbindung testen: `cd backend && .venv/bin/python -c "from app.core.config import settings; from sqlalchemy import create_engine,text; e=create_engine(settings.database_url); print(e.connect().execute(text('SELECT COUNT(*) FROM users')).fetchone())"`

### Bekannte Fixes (nicht rückgängig machen)
- **bcrypt**: `passlib` durch direktes `bcrypt` ersetzt in `backend/app/core/security.py` — passlib 1.7.4 ist inkompatibel mit bcrypt 4.x
- **401-Interceptor**: `frontend/lib/core/api_client.dart` leitet bei abgelaufenen Tokens automatisch zur Loginmaske weiter (via `sessionExpiredProvider`)
- **alembic.ini**: `sqlalchemy.url` ist leer — URL kommt aus `.env` über `alembic/env.py`

## Wichtige Commands

### Backend starten
```bash
cd backend
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000   # Produktion/Dev
# Docker PostgreSQL (lokal) läuft bereits: backend-db-1
```

### Backend (weitere Commands)
```bash
cd backend
.venv/bin/alembic upgrade head                              # DB-Migration ausführen
.venv/bin/alembic revision --autogenerate -m "description" # Neue Migration
pytest                                                       # Tests ausführen
```

### Frontend
```bash
cd frontend
flutter run -d chrome --web-port 3000   # Im Browser starten
flutter run                              # Auf verbundenem Gerät
flutter test                             # Tests ausführen
flutter build apk                        # Android-Build
```

## Datenmodell (Überblick)
- `users` – Alias, Email, Studiengang, Lernstil, Bio
- `subjects` – Fächer/Module
- `user_subjects` – N:M zwischen users und subjects
- `availabilities` – Zeitfenster pro User (Wochentag, Start, Ende)
- `matches` – Zwei User, Score, Status (vorgeschlagen/akzeptiert/abgelehnt)
- `messages` – Chat-Nachrichten pro Match
- `study_sessions` – Geplante Lerntreffen mit Datum, Uhrzeit, Raum
- `rooms` – Campusräume mit Kapazität und Verfügbarkeit

## Matching-Logik (Überblick)
Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit
Scoring: Fach 40 % | Lernstil 25 % | Zeitüberlappung 20 % | Studiengang 10 % | Lernziel 5 %

## Was Claude NICHT tun soll
- Kein ML/KI im Matching – regelbasiert reicht für MVP
- Keine Over-Engineering (KISS-Prinzip)
- Keine Features außerhalb des MVP-Umfangs ohne Rückfrage
- Keine Änderungen an der DB-Struktur ohne Alembic-Migration

## GitLab & Jira
- GitLab-Repo-URL: (wird ergänzt)
- Jira-Projekt-Key: (wird ergänzt)
- Branch-Konvention: `feature/SM-<ticket-nr>-kurzbeschreibung`
- Commit-Format: `SM-<nr>: Kurzbeschreibung`
