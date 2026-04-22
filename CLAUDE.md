# StudyMatch – CLAUDE.md

## Projektkontext
Mobile App zur Vermittlung von Lernpartnern und Lernräumen auf dem Campus.
Uni-Projekt, MVP in 8 Wochen, agile Entwicklung mit Jira + GitLab.

## Tech Stack
| Schicht | Technologie |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Python 3.11+, FastAPI |
| Datenbank | PostgreSQL |
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

## Wichtige Commands

### Backend
```bash
cd backend
python -m uvicorn app.main:app --reload          # Dev-Server starten
alembic upgrade head                              # DB-Migration ausführen
alembic revision --autogenerate -m "description" # Neue Migration
pytest                                            # Tests ausführen
```

### Frontend
```bash
cd frontend
flutter run                # App starten
flutter test               # Tests ausführen
flutter build apk          # Android-Build
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
