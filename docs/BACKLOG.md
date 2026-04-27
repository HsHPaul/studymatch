# StudyMatch – Product Backlog

Generiert aus Code-Review mit FastAPI Expert, Secure Code Guardian und Test Master Skills.  
Story Points: XS=1 | S=2 | M=3 | L=5 | XL=8

---

## Epic-Übersicht

| Epic | Beschreibung |
|---|---|
| E-01 Backend Security | Auth-Härtung, CORS, Rate Limiting, Validierung |
| E-02 Backend Tests | Unit- und Integrationstests, Test-Infrastruktur |
| E-03 Flutter Setup | Grundgerüst, Navigation, HTTP-Client, State |
| E-04 Flutter Auth | Register- und Login-Screen |
| E-05 Flutter Profil | Profil anlegen, Fächer und Zeitfenster verwalten |
| E-06 Flutter Matching | Match-Liste anzeigen und Details |
| E-07 Chat Echtzeit | WebSocket Connection Manager, Flutter Chat |
| E-08 Sessions & Räume | Lerntreffen planen, Raumvorschläge |
| E-09 Seed & DevEx | Testdaten, Health Check, Entwicklungskomfort |

---

## Sprint 1 – Security & Grundlagen (aktuell)

### SM-01 · CORS korrekt konfigurieren · **E-01** · S · 🔴 Critical
**Problem:** `allow_origins=["*"]` mit `allow_credentials=True` ist laut CORS-Spec ungültig.
Browser blockieren credentialed Requests bei Wildcard-Origin — d.h. das Frontend kann
aktuell keine authentifizierten Anfragen stellen.

**Akzeptanzkriterien:**
- [ ] `allow_origins` enthält nur explizite Origins (z.B. `http://localhost:3000`, Flutter-Schema)
- [ ] Credentialed Requests vom Flutter-Client funktionieren
- [ ] Kein Wildcard mehr in Produktion

---

### SM-02 · Rate Limiting auf Auth-Endpunkte · **E-01** · M · 🔴 Critical
**Problem:** `/auth/login` und `/auth/register` sind offen für Brute-Force-Angriffe.

**Akzeptanzkriterien:**
- [ ] `slowapi` in requirements.txt eingetragen
- [ ] Login: max. 5 Versuche / Minute pro IP
- [ ] Register: max. 10 Versuche / Minute pro IP
- [ ] Überschreitung → 429 Too Many Requests

---

### SM-03 · WebSocket-Auth implementieren · **E-01** · M · 🔴 Critical
**Problem:** `/chat/ws/{match_id}` akzeptiert jeden unauthentifizierten Client.
Jeder kann fremde Chats lesen/beschreiben.

**Akzeptanzkriterien:**
- [ ] Token als Query-Parameter (`?token=...`) wird beim Connect geprüft
- [ ] Ungültiger/fehlender Token → WebSocket wird sofort geschlossen (Code 4001)
- [ ] Nur Teilnehmer des Matches dürfen sich verbinden

---

### SM-04 · Passwort-Mindestlänge und Input-Validierung · **E-01** · S · 🟠 High
**Problem:** Ein-Zeichen-Passwörter werden akzeptiert. Felder ohne Längenlimits.

**Akzeptanzkriterien:**
- [ ] `password`: `min_length=8`
- [ ] `alias`: `min_length=2`, `max_length=50`
- [ ] `bio`: `max_length=500`
- [ ] `MessageCreate.content`: `min_length=1`, `max_length=2000`
- [ ] `AvailabilityCreate`: Validator der sicherstellt `end_time > start_time`

---

### SM-05 · E-Mail-Enumeration verhindern · **E-01** · S · 🟠 High
**Problem:** Register gibt `"E-Mail bereits registriert"` zurück → Angreifer kann prüfen ob
eine E-Mail existiert.

**Akzeptanzkriterien:**
- [ ] Generische Fehlermeldung bei doppelter E-Mail (z.B. "Registrierung nicht möglich")
- [ ] HTTP-Statuscode bleibt 400 (keine 200-Fake-Antwort nötig für MVP)

---

### SM-06 · JWT-Algorithmus hardcoden · **E-01** · S · 🟡 Medium
**Problem:** Algorithmus kommt aus `.env` → bei `ALGORITHM=none` könnten unsignierte
Tokens akzeptiert werden.

**Akzeptanzkriterien:**
- [ ] `decode_token()` übergibt `algorithms=["HS256"]` hardcoded, nicht aus Settings
- [ ] Settings-Feld `algorithm` kann entfernt werden

---

### SM-07 · Seed-Daten Script · **E-09** · M · 🟡 Medium
**Problem:** Keine Testdaten → Matching-Endpunkt liefert immer leere Liste.
Kein Demo-Betrieb ohne Daten.

**Akzeptanzkriterien:**
- [ ] `backend/scripts/seed.py` legt an: 10 Fächer, 5 Räume, 3 Demo-User mit Profil/Fächern/Zeitfenstern
- [ ] Aufruf: `python scripts/seed.py`
- [ ] Idempotent (mehrfaches Ausführen macht nichts kaputt)

---

### SM-08 · Health Check mit DB-Verbindungstest · **E-09** · XS · 🟢 Low
**Problem:** `GET /health` gibt immer `ok` zurück, auch wenn die DB nicht erreichbar ist.

**Akzeptanzkriterien:**
- [ ] Health-Endpoint führt `db.execute("SELECT 1")` aus
- [ ] DB nicht erreichbar → 503 Service Unavailable

---

## Sprint 2 – Flutter Grundgerüst & Backend Tests

### SM-09 · Flutter Projektstruktur aufsetzen · **E-03** · L
**Akzeptanzkriterien:**
- [ ] `flutter create` mit korrektem Package-Name
- [ ] Feature-first Ordnerstruktur: `features/auth`, `features/profile`, `features/matching`, `features/chat`, `features/sessions`
- [ ] `go_router` konfiguriert mit allen Route-Namen
- [ ] `riverpod` + `flutter_riverpod` eingerichtet
- [ ] `dio` HTTP-Client mit BaseURL und Auth-Interceptor (JWT automatisch anhängen)
- [ ] `flutter analyze` ohne Fehler

---

### SM-10 · Flutter Auth Feature · **E-04** · L
**Akzeptanzkriterien:**
- [ ] Register-Screen: Alias, E-Mail, Passwort, Studiengang
- [ ] Login-Screen: E-Mail, Passwort
- [ ] JWT-Token wird sicher im `flutter_secure_storage` gespeichert
- [ ] Nach Login → Weiterleitung zu Matching-Screen
- [ ] Fehlerbehandlung: falsches Passwort, E-Mail existiert bereits

---

### SM-11 · Flutter Profil Feature · **E-05** · L
**Akzeptanzkriterien:**
- [ ] Profil-Screen zeigt: Alias, Studiengang, Lernstil, Bio
- [ ] Fächer hinzufügen/entfernen (aus vorhandener Subject-Liste)
- [ ] Zeitfenster hinzufügen/entfernen (Wochentag + Uhrzeit-Picker)
- [ ] PATCH /profiles/me bei Speichern
- [ ] Validierung: mind. 1 Fach und 1 Zeitfenster vor Matching pflichtend

---

### SM-12 · Backend Test-Infrastruktur · **E-02** · M
**Akzeptanzkriterien:**
- [ ] `pytest`, `httpx`, `pytest-cov` in `requirements-dev.txt`
- [ ] `tests/conftest.py` mit: SQLite In-Memory DB, `client`-Fixture, `auth_headers`-Fixture
- [ ] Model-Factories: `make_user()`, `make_subject()`, `make_availability()`, `make_match()`
- [ ] `pytest` läuft ohne Fehler (auch wenn noch keine Tests vorhanden)

---

### SM-13 · Unit Tests – Matching Service · **E-02** · L
Abhängigkeit: SM-12

**Akzeptanzkriterien:**
- [ ] `_find_time_overlaps`: 8 Szenarien getestet (gleicher Tag, verschiedene Tage, angrenzend, leer, mehrere Slots, enthaltenes Fenster, identisch)
- [ ] `_calculate_score`: alle Gewichtungs-Kombinationen getestet
- [ ] Gewichte summieren sich auf 1.0 (Assertions-Test)
- [ ] `find_matches`: selbst-ausschluss, kein gemeinsames Fach, kein Zeitfenster, Top-10-Limit
- [ ] Coverage auf matching_service.py ≥ 95 %

---

### SM-14 · Unit Tests – Security · **E-02** · S
Abhängigkeit: SM-12

**Akzeptanzkriterien:**
- [ ] `hash_password` / `verify_password`: korrekt/falsch/leer
- [ ] `create_access_token` / `decode_token`: Roundtrip, abgelaufen, ungültig

---

### SM-15 · Integrationstests – Auth & Profile Endpoints · **E-02** · L
Abhängigkeit: SM-12

**Akzeptanzkriterien:**
- [ ] Auth: register success/duplicate/invalid-email, login success/wrong-password
- [ ] Profile: get/patch, add/remove subject, add/remove availability (inkl. ownership-check)
- [ ] Alle Tests grün, Coverage ≥ 80 %

---

## Sprint 3 – Chat, Sessions & Räume

### SM-16 · Flutter Matching Feature · **E-06** · L
**Akzeptanzkriterien:**
- [ ] Match-Liste mit Score, Alias, gemeinsamen Fächern, Zeitüberschneidungen
- [ ] Tap → Detail-Screen mit vollständigem Profil
- [ ] "Kontakt aufnehmen" öffnet Chat
- [ ] Leerer State wenn keine Matches vorhanden

---

### SM-17 · WebSocket Connection Manager Backend · **E-07** · L
**Akzeptanzkriterien:**
- [ ] `ConnectionManager`-Klasse in `app/core/websocket.py`
- [ ] Verbindungen werden pro `match_id` getrackt
- [ ] Nachricht wird an beide Teilnehmer des Matches gebroadcastet
- [ ] Disconnect wird sauber bereinigt (kein Memory Leak)
- [ ] Auth via Token-Query-Parameter (SM-03 Voraussetzung)

---

### SM-18 · Flutter Chat Feature · **E-07** · L
Abhängigkeit: SM-17

**Akzeptanzkriterien:**
- [ ] Chat-Screen mit Nachrichtenverlauf (Blasen-Layout, eigene/fremde Nachrichten)
- [ ] Nachricht senden per Text-Input
- [ ] Echtzeit-Empfang via WebSocket
- [ ] Fallback auf REST wenn WebSocket nicht verbunden

---

### SM-19 · Flutter Sessions Feature · **E-08** · M
**Akzeptanzkriterien:**
- [ ] Termin vorschlagen: Datum, Uhrzeit, Raum auswählen
- [ ] POST /sessions
- [ ] Terminübersicht: kommende Treffen in Liste

---

### SM-20 · Flutter Räume Feature · **E-08** · S
**Akzeptanzkriterien:**
- [ ] Raumliste aus GET /rooms bei Terminplanung anzeigen
- [ ] Filter nach Kapazität (optional)

---

### SM-21 · Integrationstests – Matching, Chat, Sessions · **E-02** · L
Abhängigkeit: SM-12, SM-13

**Akzeptanzkriterien:**
- [ ] Matching: leere Liste, kein gemeinsames Fach, kein Zeitfenster, Sortierung, Score-Wert
- [ ] Chat: Nachricht senden/lesen, Zugriff auf fremdes Match → 403
- [ ] Sessions: anlegen mit gültigem Match, fremdes Match → 403, eigene Sessions abfragen
- [ ] Rooms: Liste leer, Liste mit Daten, unauthentifiziert → 403

---

## Sprint 4 – Polish & Demo

### SM-22 · Match ablehnen · **E-06** · S
**Akzeptanzkriterien:**
- [ ] PATCH /matches/{id} mit `status: "abgelehnt"` Endpoint
- [ ] Abgelehnte Matches erscheinen nicht mehr in der Liste
- [ ] Flutter: Swipe oder Button zum Ablehnen

---

### SM-23 · Refresh Token · **E-01** · L
**Problem:** Nach 30 Minuten muss der User sich neu einloggen. Kein Refresh-Flow vorhanden.

**Akzeptanzkriterien:**
- [ ] `/auth/refresh` Endpoint mit Refresh-Token (7 Tage gültig)
- [ ] Flutter: Token automatisch erneuern bevor er abläuft
- [ ] Refresh-Token wird sicher gespeichert

---

### SM-24 · Security Headers · **E-01** · S
**Akzeptanzkriterien:**
- [ ] `secure`-Library oder Custom Middleware
- [ ] Headers gesetzt: `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`
- [ ] HSTS nur in Produktion aktiv

---

### SM-25 · Flutter Widget Tests · **E-02** · L
**Akzeptanzkriterien:**
- [ ] Auth-Screens: Validierung, Error-States
- [ ] Profil-Screen: Fach hinzufügen/entfernen
- [ ] Match-Liste: leerer State, gefüllte Liste

---

### SM-26 · E2E Test (Playwright) · **E-02** · M
**Akzeptanzkriterien:**
- [ ] Szenario: Register → Profil anlegen → Match abrufen → Nachricht senden → Session anlegen
- [ ] Läuft gegen lokale Backend + DB

---

### SM-27 · Async SQLAlchemy Migration · **E-01** · XL · 🟢 Low (Post-MVP)
**Problem:** Aktuell sync SQLAlchemy. Bei vielen gleichzeitigen Requests blockiert die DB.
Für den Uni-MVP mit wenigen Nutzern kein Problem.

**Akzeptanzkriterien:**
- [ ] `asyncpg` statt `psycopg2-binary`
- [ ] `AsyncEngine`, `AsyncSession`, `async_sessionmaker`
- [ ] Alle Route-Handler und Services auf `async def` umgestellt
- [ ] Alle Tests weiterhin grün

---

## Backlog (ohne Sprint)

| ID | Titel | Epic | Points |
|---|---|---|---|
| SM-28 | Push-Notifications Konzept/Mockup | E-07 | M |
| SM-29 | Bewertung nach Lerntreffen (1–5 Sterne) | E-08 | M |
| SM-30 | Match-Filter (Lernstil, Studiengang) | E-06 | S |
| SM-31 | Terminübersicht (vergangene Treffen) | E-08 | S |
| SM-32 | Pagingierung auf /matches und /messages | E-01 | M |
| SM-33 | Async SQLAlchemy (SM-27) | E-01 | XL |
| SM-34 | CRUD-Layer Refactoring | E-01 | M |
| SM-35 | OpenAPI Error-Response Dokumentation | E-09 | S |

---

## Bekannte Bugs (sofort fixen)

| Bug | Datei | Priorität |
|---|---|---|
| CORS Wildcard + Credentials (spec violation) | `app/main.py` | 🔴 Kritisch |
| Scoring-Gewichte summierten sich auf 0.95 | `matching_service.py` | ✅ Gefixt |
| `datetime.utcnow()` Deprecation-Warning in security.py | `app/core/security.py` | 🟡 Low |

---

## Sprint-Übersicht

| Sprint | Fokus | Stories | Points |
|---|---|---|---|
| Sprint 1 (aktuell) | Security-Härtung + Seed-Daten | SM-01 bis SM-08 | ~20 |
| Sprint 2 | Flutter Grundgerüst + Backend Tests | SM-09 bis SM-15 | ~35 |
| Sprint 3 | Chat, Sessions, Räume | SM-16 bis SM-21 | ~35 |
| Sprint 4 | Polish, Tests, Demo | SM-22 bis SM-26 | ~25 |
| Backlog | Post-MVP Features | SM-27 bis SM-35 | ~40 |
