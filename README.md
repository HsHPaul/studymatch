# StudyMatch

Mobile App zur Vermittlung von Lernpartnern und Lernräumen auf dem Campus.  
Studierende legen ein Profil an, geben Fach, Lernstil und Verfügbarkeit an, schicken Match-Anfragen an passende Lernpartner und planen Termine über den integrierten Chat.

**Status:** MVP in Entwicklung | Uni-Projekt | 8-Wochen-Sprint

---

## Für KI-Assistenten (Claude, Claude Code, ChatGPT)

Dieses Projekt ist eine mobile App mit folgendem Stack:

- **Frontend:** Flutter (Dart) — vollständig implementiert inkl. eigenem Designsystem
- **Backend:** Python 3.11+, FastAPI — vollständig implementiert
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
│   ├── app_colors.dart   → Zentrale Farbkonstanten (AppColors)
│   ├── api_client.dart   → Dio + JWT-Interceptor + 401-Logout
│   ├── router.dart       → GoRouter (Auth-Guard, ShellRoute, _StyledNavBar)
│   └── theme.dart        → Material 3 Theme (vollständiges Designsystem)
├── features/
│   ├── auth/             → Login, Register, Passwort vergessen, AuthNotifier
│   ├── profile/          → Profil bearbeiten, Fächer, Zeitfenster, Passwort ändern, Account löschen
│   ├── matching/         → Vorschläge / Anfragen / Bestätigte Matches (3 Tabs), Detail-Ansicht
│   ├── chat/             → WebSocket + REST-Fallback, Chat-UI, Terminvorschlag aus Chat
│   └── sessions/         → Lerntreffen-Liste, Mini-Kalender, Terminbearbeitung mit Bestätigung
└── shared/
    ├── models/           → Dart-Modelle für alle Entities
    └── widgets/          → LoadingIndicator, ErrorView, StudyMatchLogo
```

### Matching-Anfragen-Flow
1. `GET /matches` berechnet Vorschläge per Algorithmus (regelbasiert, kein ML)
2. User A sendet Anfrage: `POST /matches/{id}/request` → Status `angefragt`
3. User B sieht eingehende Anfragen im "Anfragen"-Tab → `POST /matches/{id}/accept` oder `/decline`
4. Nur `akzeptiert`-Matches erlauben Chat und Terminplanung

### Session-Anfragen-Flow
1. Termin wird aus dem Chat vorgeschlagen (Kalender-Icon in AppBar) → Status `angefragt`
2. Partner sieht Banner im Chat → kann annehmen oder ablehnen
3. Nur `geplant`/`bestaetigt`-Sessions erscheinen im Termine-Tab
4. Bestehende Termine können bearbeitet werden → Änderungsanfrage muss bestätigt werden

### Matching-Algorithmus
Regelbasiert (kein ML). Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit.  
Scoring: Fach 45% | Lernstil 25% | Zeitüberlappung 20% | Studiengang 10%

### Bekannte Fixes / wichtige Hinweise
- **bcrypt:** `passlib` durch direktes `bcrypt` ersetzt (`security.py`) — passlib 1.7.4 ist inkompatibel mit bcrypt 4.x
- **401-Interceptor:** Bei abgelaufenem Token leitet die App automatisch zur Loginmaske (via `sessionExpiredProvider`)
- **sessionExpiredProvider-Reset:** `AuthNotifier._clearUserData()` setzt `sessionExpiredProvider` auf `false` zurück — nötig damit spätere 401s erneut erkannt werden
- **Alembic:** `alembic.ini` hat leeres `sqlalchemy.url` — URL kommt aus `.env` über `alembic/env.py`
- **Provider-Reset:** `AuthNotifier._clearUserData()` invalidiert alle nutzerspezifischen Provider bei Login/Logout
- **Auth-Hint-Fix:** `MatchListScreen` prüft Auth-State in Fehlerfall, triggert Reload via `ref.listen` wenn Auth bereit — verhindert falschen 401 beim App-Start

### API-Endpunkte (Überblick)

| Methode | Pfad | Beschreibung |
|---|---|---|
| POST | `/api/v1/auth/register` | Neuen Account anlegen |
| POST | `/api/v1/auth/login` | Login → JWT-Token |
| POST | `/api/v1/auth/reset-password` | Passwort zurücksetzen (ohne E-Mail-Verifizierung, MVP) |
| GET | `/api/v1/profiles/me` | Eigenes Profil abrufen |
| PATCH | `/api/v1/profiles/me` | Profil bearbeiten |
| PATCH | `/api/v1/profiles/me/password` | Passwort ändern (mit aktuellem Passwort) |
| DELETE | `/api/v1/profiles/me` | Account vollständig löschen |
| POST | `/api/v1/profiles/me/subjects` | Fach hinzufügen |
| DELETE | `/api/v1/profiles/me/subjects/{id}` | Fach entfernen |
| POST | `/api/v1/profiles/me/availabilities` | Zeitfenster hinzufügen |
| DELETE | `/api/v1/profiles/me/availabilities/{id}` | Zeitfenster entfernen |
| GET | `/api/v1/profiles/subjects` | Alle verfügbaren Fächer |
| GET | `/api/v1/matches` | Vorschläge + bestätigte Matches (mit Status) |
| POST | `/api/v1/matches/{id}/request` | Match-Anfrage senden |
| POST | `/api/v1/matches/{id}/accept` | Match-Anfrage annehmen |
| POST | `/api/v1/matches/{id}/decline` | Match-Anfrage ablehnen |
| GET | `/api/v1/chat/{match_id}/messages` | Chatverlauf laden |
| POST | `/api/v1/chat/{match_id}/messages` | Nachricht senden |
| WS | `/api/v1/chat/ws/{match_id}` | Echtzeit-Chat |
| POST | `/api/v1/sessions` | Terminanfrage stellen (Status: `angefragt`) |
| GET | `/api/v1/sessions` | Bestätigte Termine (`geplant`/`bestaetigt`) |
| GET | `/api/v1/sessions/pending/{match_id}` | Offene Terminanfragen für Chat-Banner |
| POST | `/api/v1/sessions/{id}/accept` | Terminanfrage annehmen |
| POST | `/api/v1/sessions/{id}/decline` | Terminanfrage ablehnen |
| PATCH | `/api/v1/sessions/{id}/propose-edit` | Terminänderung vorschlagen |
| POST | `/api/v1/sessions/{id}/accept-edit` | Terminänderung bestätigen |
| POST | `/api/v1/sessions/{id}/decline-edit` | Terminänderung ablehnen |
| GET | `/api/v1/rooms` | Verfügbare Räume |
| GET | `/health` | Server-Status |

### Datenbank-Schema (Enums)
- `MatchStatus`: `vorgeschlagen` → `angefragt` → `akzeptiert` / `abgelehnt`
- `SessionStatus`: `angefragt` → `geplant` → `bestaetigt` / `abgesagt`

---

## Für Menschen (Quickstart)

### Voraussetzungen
- Python 3.12
- Flutter SDK 3.x
- Docker Desktop (nur für lokale DB)

### Backend starten

```bash
cd backend

# 1. .env anlegen (einmalig)
cp .env.example .env
# DATABASE_URL auf Supabase setzen:
# postgresql://postgres:PASSWORT@db.flqhltziakhhkviyomzl.supabase.co:5432/postgres?sslmode=require

# 2. Python-Umgebung einrichten (einmalig)
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt

# 3. Migrationen ausführen
.venv/bin/alembic upgrade head

# 4. Server starten
.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

API: `http://localhost:8000` | Docs: `http://localhost:8000/docs`

### Frontend starten

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 3000
```

### Umgebungsvariablen (`.env`)

| Variable | Beschreibung |
|---|---|
| `DATABASE_URL` | PostgreSQL-Verbindung (Supabase oder lokal) |
| `SECRET_KEY` | JWT-Signing-Key |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token-Gültigkeit (Standard: 30) |

### Nützliche Befehle

```bash
# Neue DB-Migration
.venv/bin/alembic revision --autogenerate -m "beschreibung"
.venv/bin/alembic upgrade head

# Tests
pytest

# Flutter
flutter test
flutter build apk
```

---

## Datenmodell

```
users ──────< user_subjects >────── subjects
  │                                  (Fächer/Module)
  └──< availabilities
         (Zeitfenster pro Wochentag)

matches (user_a, user_b, status, requested_by_id)
   │──────< messages (Chat)
   └──────< study_sessions (created_by_id, edit_proposed_by_id) >── rooms
```

---

## MVP-Scope

**Enthalten:** Registrierung, Profil, Fächer, Lernstil, Zeitfenster, Match-Anfragen, Chat, Terminvorschläge aus Chat, Terminbearbeitung mit Bestätigung, Passwort ändern/zurücksetzen, Account löschen  
**Nicht im MVP:** E-Mail-Versand, Video-Call, Kalender-Sync, Hochschul-SSO, Gruppenmatching, Gamification

---

## Team

Uni-Projekt — Backend mit FastAPI + PostgreSQL, Frontend mit Flutter.  
Projektmanagement via Jira, Versionskontrolle via GitLab (GWDG).
