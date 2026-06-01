# StudyMatch

Mobile App zur Vermittlung von Lernpartnern und Lernräumen auf dem Campus.  
Studierende legen ein Profil an, geben Fach, Lernstil und Verfügbarkeit an und erhalten passende Lernpartner-Vorschläge. Über einen integrierten Chat können Termine abgestimmt und Campusräume gefunden werden.

**Status:** MVP in Entwicklung | Uni-Projekt | 8-Wochen-Sprint

---

## Für KI-Assistenten (Claude, Claude Code, ChatGPT)

Dieses Projekt ist eine mobile App mit folgendem Stack:

- **Frontend:** Flutter (Dart) — vollständig implementiert inkl. eigenem Designsystem (Sprint 3)
- **Backend:** Python 3.11+, FastAPI — vollständig als Grundgerüst vorhanden
- **Datenbank:** PostgreSQL via **Supabase** (Produktion) + Docker lokal
- **Auth:** JWT (python-jose + bcrypt direkt — kein passlib)
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

### Architektur (Frontend)
```
frontend/lib/
├── main.dart             → App-Einstiegspunkt (ProviderScope)
├── core/
│   ├── app_colors.dart   → Zentrale Farbkonstanten (AppColors, AppShadows)
│   ├── api_client.dart   → Dio + JWT-Interceptor + 401-Logout
│   ├── router.dart       → GoRouter (Auth-Guard, ShellRoute, _StyledNavBar)
│   └── theme.dart        → Material 3 Theme (vollständiges Designsystem)
├── features/
│   ├── auth/             → Login, Register, AuthNotifier (JWT in SecureStorage)
│   ├── profile/          → Profil bearbeiten, Fächer, Zeitfenster
│   ├── matching/         → Match-Liste mit Score-Kreis, Detail-Ansicht
│   ├── chat/             → WebSocket + REST-Fallback, Chat-UI
│   └── sessions/         → Lerntreffen-Liste, Mini-Kalender, Termin anlegen
└── shared/
    ├── models/           → Dart-Modelle für alle Entities
    └── widgets/          → LoadingIndicator, ErrorView, StudyMatchLogo
```

### Designsystem (Frontend)
Alle Farben sind in `core/app_colors.dart` zentral definiert:

| Konstante | Hex | Verwendung |
|---|---|---|
| `AppColors.primary` | `#6F35D4` | Buttons, Fokus, Navigation-Indikator |
| `AppColors.navy` | `#0B1B3A` | Headlines, Texte |
| `AppColors.orange` | `#F0441A` | Logo-Akzent |
| `AppColors.background` | `#F8F8FB` | Scaffold-Hintergrund |
| `AppColors.cardWhite` | `#FFFFFF` | Cards, Input-Felder |
| `AppColors.muted` | `#8A8FAB` | Sekundärtexte, inaktive Icons |

### Matching-Algorithmus
Regelbasiert (kein ML). Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit.  
Scoring: Fach 45% | Lernstil 25% | Zeitüberlappung 20% | Studiengang 10%

`GET /matches` legt automatisch Match-Datensätze in der DB an (find-or-create), damit `POST /sessions` eine gültige `match_id` bekommt.

### Bekannte Fixes / wichtige Hinweise
- **bcrypt:** `passlib` durch direktes `bcrypt` ersetzt (`security.py`) — passlib 1.7.4 ist inkompatibel mit bcrypt 4.x, nicht rückgängig machen
- **401-Interceptor:** Bei abgelaufenem Token leitet die App automatisch zur Loginmaske (via `sessionExpiredProvider` in `api_client.dart`)
- **Alembic:** `alembic.ini` hat leeres `sqlalchemy.url` — URL kommt aus `.env` über `alembic/env.py`
- **Provider-Reset:** `AuthNotifier._clearUserData()` invalidiert alle nutzerspezifischen Provider bei Login/Logout — nicht entfernen
- **match_id:** `GET /matches` persistiert Match-Datensätze automatisch und gibt `match_id` zurück — nötig für Session-Erstellung

### Was noch fehlt (nächste Sprints)
- WebSocket-Connection-Manager für Echtzeit-Chat (Sprint 3)
- Tests (pytest Backend, flutter test Frontend)
- GitLab CI/CD Pipeline
- `_isOwnMessage` in Chat korrekt implementieren (benötigt User-UUID aus Profil)

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
- Python 3.12
- Flutter SDK 3.x
- Docker Desktop (nur für lokale DB)

### Backend starten (Produktion/Supabase)

```bash
cd backend

# 1. .env anlegen (einmalig – wird nicht committet)
cp .env.example .env
# DATABASE_URL auf Supabase-URL setzen:
# postgresql://postgres:PASSWORT@db.flqhltziakhhkviyomzl.supabase.co:5432/postgres?sslmode=require

# 2. Python-Umgebung einrichten (einmalig)
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 3. Migrationen ausführen (nur bei neuer DB)
.venv/bin/alembic upgrade head

# 4. Server starten
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Backend starten (lokal mit Docker)

```bash
cd backend

# Docker-PostgreSQL starten
docker compose up -d

# .env auf lokale DB setzen:
# DATABASE_URL=postgresql://studymatch:studymatch@localhost:5432/studymatch

.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
```

API läuft unter: `http://localhost:8000`  
Interaktive Dokumentation: `http://localhost:8000/docs`

### Frontend starten

```bash
cd frontend

# Abhängigkeiten installieren (einmalig)
flutter pub get

# Im Browser starten
flutter run -d chrome --web-port 3000

# Auf verbundenem Gerät
flutter run

# Android-Build
flutter build apk
```

### Umgebungsvariablen (`.env`)

| Variable | Beschreibung | Beispiel |
|---|---|---|
| `DATABASE_URL` | PostgreSQL-Verbindung | `postgresql://postgres:pw@host:5432/postgres?sslmode=require` |
| `SECRET_KEY` | JWT-Signing-Key (langer Zufallsstring) | `supersecretkey123...` |
| `ALGORITHM` | JWT-Algorithmus | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token-Gültigkeit | `30` |

### DB-Verbindung testen

```bash
cd backend
.venv/bin/python -c "
from app.core.config import settings
from sqlalchemy import create_engine, text, inspect
engine = create_engine(settings.database_url)
with engine.connect() as conn:
    print('OK:', conn.execute(text('SELECT version()')).fetchone()[0][:40])
    print('Tabellen:', inspect(engine).get_table_names())
"
```

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
| GET | `/api/v1/profiles/subjects` | Alle verfügbaren Fächer abrufen |
| GET | `/api/v1/matches` | Passende Lernpartner abrufen + Match-Datensätze anlegen |
| GET | `/api/v1/chat/{match_id}/messages` | Chatverlauf laden |
| POST | `/api/v1/chat/{match_id}/messages` | Nachricht senden |
| WS | `/api/v1/chat/ws/{match_id}` | Echtzeit-Chat |
| POST | `/api/v1/sessions` | Lerntreffen anlegen |
| GET | `/api/v1/sessions` | Eigene Lerntreffen abrufen |
| GET | `/api/v1/rooms` | Verfügbare Räume abrufen |
| GET | `/health` | Server-Status |

### Nützliche Befehle

```bash
# Neue DB-Migration generieren (nach Modelländerung)
.venv/bin/alembic revision --autogenerate -m "beschreibung"

# Migration ausführen
.venv/bin/alembic upgrade head

# Migration rückgängig machen
.venv/bin/alembic downgrade -1

# Tests ausführen
pytest

# Lokale Datenbank zurücksetzen (Vorsicht!)
docker compose down -v && docker compose up -d && .venv/bin/alembic upgrade head
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
