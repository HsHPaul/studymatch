# StudyMatch – Systemarchitektur

## Systemübersicht

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│                   (Android / iOS / Web)                     │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │  Profil  │  │ Matching │  │   Chat   │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│        │             │             │              │         │
│        └─────────────┴──────┬──────┴──────────────┘        │
│                             │                               │
│                    Dio HTTP-Client                          │
│                  + JWT Auth-Interceptor                     │
└─────────────────────────────┬───────────────────────────────┘
                              │
              HTTPS (REST) + WebSocket (WS)
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                    FastAPI Backend                          │
│                   (Python 3.11+)                            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    API Layer                         │  │
│  │  /api/v1/auth  /profiles  /matches  /chat  /rooms   │  │
│  └──────────────────────────┬─────────────────────────┘   │
│                             │                               │
│  ┌──────────────────────────▼─────────────────────────┐    │
│  │                 Service Layer                       │    │
│  │         matching_service    room_service            │    │
│  └──────────────────────────┬─────────────────────────┘    │
│                             │                               │
│  ┌──────────────────────────▼─────────────────────────┐    │
│  │              SQLAlchemy ORM (sync)                  │    │
│  └──────────────────────────┬─────────────────────────┘    │
└─────────────────────────────┼───────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────┐
│                     PostgreSQL                              │
│                  (Docker im Dev, extern in Prod)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Schicht | Technologie | Begründung |
|---|---|---|
| Frontend | Flutter 3 (Dart) | Cross-Platform (Android + iOS), eine Codebase |
| Backend | Python 3.11, FastAPI | Schnelle Entwicklung, automatische OpenAPI-Docs |
| Datenbank | PostgreSQL | Relationale Daten, gute ORM-Unterstützung |
| ORM | SQLAlchemy 2.x | Python-Standard, Alembic-Migration inklusive |
| Auth | JWT (python-jose + bcrypt) | Stateless, kein Session-Storage nötig |
| Echtzeit-Chat | WebSockets (FastAPI native) | Kein externer Service nötig für MVP |
| State Management | Riverpod (Flutter) | Reaktiv, testbar, kein Boilerplate |
| Navigation | go_router (Flutter) | Deep-Link-fähig, deklarativ |
| HTTP-Client | Dio (Flutter) | Interceptors für JWT, Error-Handling |
| CI/CD | GitLab CI | Bereits vorhanden (Uni-Infrastruktur) |

---

## Datenbankschema

```
users
├── id (UUID, PK)
├── alias (VARCHAR 50)
├── email (VARCHAR 255, UNIQUE)
├── hashed_password (VARCHAR)
├── studiengang (VARCHAR 100)
├── lernstil (ENUM: still | gemischt | diskutierend)
└── bio (TEXT)

subjects
├── id (UUID, PK)
├── name (VARCHAR 100)
└── kuerzel (VARCHAR 20)

user_subjects  ← N:M zwischen users und subjects
├── user_id (FK → users)
└── subject_id (FK → subjects)

availabilities  ← Zeitfenster pro Nutzer
├── id (UUID, PK)
├── user_id (FK → users)
├── wochentag (ENUM: montag … sonntag)
├── start_time (TIME)
└── end_time (TIME)

matches
├── id (UUID, PK)
├── user_a_id (FK → users)
├── user_b_id (FK → users)
├── score (FLOAT)
└── status (ENUM: vorgeschlagen | akzeptiert | abgelehnt)

messages
├── id (UUID, PK)
├── match_id (FK → matches)
├── sender_id (FK → users)
├── content (TEXT)
└── sent_at (TIMESTAMP)

study_sessions
├── id (UUID, PK)
├── match_id (FK → matches)
├── datum (DATE)
├── uhrzeit (TIME)
├── raum_id (FK → rooms)
└── status (ENUM: geplant | abgeschlossen | abgesagt)

rooms
├── id (UUID, PK)
├── gebaeude (VARCHAR 100)
├── raumname (VARCHAR 50)
└── kapazitaet (INTEGER)
```

---

## Matching-Algorithmus

Der Algorithmus ist vollständig regelbasiert (kein ML).

### Pflichtkriterien (K.O.-Kriterien)
Ein Kandidat wird nur berücksichtigt wenn **beide** Bedingungen erfüllt sind:
1. Mindestens **1 gemeinsames Fach**
2. Mindestens **1 überlappende Verfügbarkeit** (gleicher Wochentag, überschneidende Uhrzeiten)

### Scoring
Erfüllte Kandidaten erhalten einen Score zwischen 0.0 und 1.0:

| Kriterium | Gewicht | Berechnung |
|---|---|---|
| Fach-Übereinstimmung | 45 % | `min(gemeinsame_fächer / eigene_fächer, 1.0)` |
| Lernstil-Match | 25 % | 1.0 wenn gleich, sonst 0 |
| Zeitfenster-Überlappung | 20 % | `min(anzahl_overlaps / 3, 1.0)` |
| Studiengang-Match | 10 % | 1.0 wenn gleich, sonst 0 |

Ergebnis: Top 10 Kandidaten sortiert nach Score (absteigend).

---

## Use Case UC-01: Lernpartner finden

**Akteur:** Studierender (eingeloggt, Profil vollständig)

**Ablauf:**
```
Nutzer                Flutter App              FastAPI              PostgreSQL
  │                       │                      │                      │
  │── "Matches" Tab ─────>│                      │                      │
  │                       │── GET /api/v1/matches>│                      │
  │                       │                      │── Lade eigenes Profil>│
  │                       │                      │<─ User + Fächer + Zeit│
  │                       │                      │── Lade Kandidaten ───>│
  │                       │                      │<─ Alle anderen User ──│
  │                       │                      │                      │
  │                       │                      │  Filter: Fach + Zeit │
  │                       │                      │  Score berechnen     │
  │                       │                      │  Top 10 sortieren    │
  │                       │                      │                      │
  │                       │<── [MatchResponse] ──│                      │
  │<── Match-Liste ───────│                      │                      │
  │                       │                      │                      │
  │── Tap auf Match ─────>│                      │                      │
  │<── Detail-Screen ─────│                      │                      │
  │                       │                      │                      │
  │── "Kontakt aufnehmen">│                      │                      │
  │                       │── WS /chat/ws/{id} ──>│                      │
```

**API-Endpunkt:**
```
GET /api/v1/matches
Authorization: Bearer <token>

Response 200:
[
  {
    "user_id": "uuid",
    "alias": "alice",
    "studiengang": "Informatik",
    "lernstil": "still",
    "gemeinsame_faecher": ["Analysis I", "Algorithmen"],
    "ueberschneidungen": [{ "wochentag": "montag", "start_time": "10:00", "end_time": "12:00" }],
    "score": 0.875
  }
]
```

---

## Ordnerstruktur

```
studymatch/                  ← GitLab-Repo-Root
├── backend/
│   ├── app/
│   │   ├── api/             ← Route Handler (auth, profiles, matching, chat, sessions, rooms)
│   │   ├── core/            ← Config, Security, DB-Connection, Rate Limiter
│   │   ├── models/          ← SQLAlchemy ORM Models + Enums
│   │   ├── schemas/         ← Pydantic Request/Response Schemas
│   │   └── services/        ← Business Logic (matching_service)
│   ├── alembic/             ← DB-Migrationen
│   ├── scripts/             ← seed.py für Demo-Daten
│   ├── tests/               ← pytest (Sprint 2)
│   └── requirements.txt
├── frontend/                ← Flutter (Sprint 2)
│   └── lib/
│       ├── core/            ← Theme, Router, HTTP-Client
│       ├── features/        ← auth, profile, matching, chat, sessions
│       └── shared/          ← Widgets, Models
└── docs/
    ├── ARCHITECTURE.md      ← dieses Dokument
    └── BACKLOG.md           ← Product Backlog (Sprint 1–4)
```
