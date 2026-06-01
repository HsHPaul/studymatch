# StudyMatch – Frontend

Flutter-App (Dart) für die StudyMatch-Plattform.  
Modernes Design mit eigenem Designsystem (Purple `#6F35D4`, Navy `#0B1B3A`, Off-White Hintergrund).

## Starten

```bash
# Abhängigkeiten installieren (einmalig)
flutter pub get

# Im Browser starten
flutter run -d chrome --web-port 3000

# Auf verbundenem Gerät / Simulator
flutter run

# Android-Build
flutter build apk
```

## Voraussetzungen
- Flutter SDK 3.x
- Backend läuft auf `http://localhost:8000` (siehe `lib/core/api_client.dart`)

## Struktur

```
lib/
├── main.dart
├── core/
│   ├── app_colors.dart   → Zentrale Farb- und Shadow-Konstanten
│   ├── api_client.dart   → Dio, JWT-Interceptor, 401-Logout
│   ├── router.dart       → GoRouter, Auth-Guard, _StyledNavBar
│   └── theme.dart        → Vollständiges Material 3 Designsystem
├── features/
│   ├── auth/             → Login, Register, AuthNotifier
│   ├── profile/          → Profil, Fächer (Chips), Zeitfenster
│   ├── matching/         → Match-Liste (Score-Kreis), Match-Detail
│   ├── chat/             → WebSocket-Chat, Nachrichtenblasen
│   └── sessions/         → Lerntreffen, Mini-Kalender, Termin anlegen
└── shared/
    ├── models/           → Match, StudySession, Room, User, Subject …
    └── widgets/          → LoadingIndicator, ErrorView, StudyMatchLogo

assets/
├── hsh_logo.png              → HSH-Logo (wird im StudyMatchLogo-Widget genutzt)
└── login_illustration.png    → Illustration auf dem Login-Screen
```

## Designsystem

Alle Farben zentral in `core/app_colors.dart`:

| Konstante | Hex | Verwendung |
|---|---|---|
| `AppColors.primary` | `#6F35D4` | Buttons, Fokus-Border, Nav-Indikator |
| `AppColors.primaryLight` | `#EDE7FF` | Chip-Hintergrund, Icon-Kreise |
| `AppColors.navy` | `#0B1B3A` | Headlines, Fließtext |
| `AppColors.orange` | `#F0441A` | Logo-Akzent |
| `AppColors.background` | `#F8F8FB` | Scaffold-Hintergrund |
| `AppColors.cardWhite` | `#FFFFFF` | Cards, Input-Felder |
| `AppColors.muted` | `#8A8FAB` | Sekundärtexte, inaktive Icons |
| `AppColors.success` | `#27AE60` | Gutes Match, bestätigte Termine |
| `AppColors.warning` | `#F39C12` | Mäßiges Match |
| `AppColors.error` | `#E74C3C` | Fehlermeldungen |

Shadow-Konstanten in `AppShadows`: `.card`, `.soft`, `.nav`

## State Management

Riverpod (`flutter_riverpod`). Alle Provider in `*_provider.dart`-Dateien neben den jeweiligen Screens.  
Keine Business-Logik in Widgets — immer in Notifier-Klassen.

## Navigation

GoRouter mit `ShellRoute` für die Bottom-Navigation (Matches / Profil / Termine).  
Auth-Guard: Nicht eingeloggte User werden automatisch zu `/login` umgeleitet.  
Chat öffnet als separater Full-Screen-Route außerhalb der Shell.

## Wichtige Hinweise

- **match_id:** `Match.matchId` enthält die UUID des DB-Match-Datensatzes — wird beim Anlegen von Lernterminen benötigt. Kommt vom Backend via `GET /matches`.
- **mounted-Checks:** Alle Notifier prüfen `if (!mounted) return` nach jedem `await`.
- **Provider-Reset:** `AuthNotifier._clearUserData()` invalidiert alle nutzerspezifischen Provider bei Login/Logout — nicht entfernen, sonst sieht ein neuer User die Daten des Vorgängers.
