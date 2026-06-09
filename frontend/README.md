# StudyMatch – Frontend

Flutter-App (Dart) für die StudyMatch-Plattform.  
Modernes Design mit eigenem Designsystem, Dark/Light-Mode-Unterstützung und direktionalen Tab-Übergängen.

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
│   ├── app_colors.dart        → Dynamische Farben (Light/Dark), statische Getter
│   ├── api_client.dart        → Dio, JWT-Interceptor, 401-Logout
│   ├── router.dart            → GoRouter, Auth-Guard, _StyledNavBar, direktionale Tab-Animationen
│   ├── theme.dart             → Material 3 Designsystem (Light + Dark Theme)
│   ├── theme_provider.dart    → Dark-Mode-Toggle, Persistenz via flutter_secure_storage
│   ├── time_picker_utils.dart → showTimePicker24h() mit deutschen Labels
│   └── blacklist_service.dart → Clientseitige Blacklist-Prüfung (Chat + E-Mail)
├── features/
│   ├── auth/             → Login, Register, Passwort vergessen, AuthNotifier
│   ├── profile/          → Profil, Fächer (Chips), Zeitfenster (mit Bearbeiten), Dark-Mode-Toggle
│   ├── matching/         → 3 Tabs: Angenommen (mit Filter) / Anfragen / Vorschläge (mit Filter)
│   ├── chat/             → WebSocket-Chat, Nachrichtenblasen, Terminvorschlag aus Chat
│   └── sessions/         → Lerntreffen, Mini-Kalender (mit Tages-Filter), Termin anlegen/bearbeiten
└── shared/
    ├── models/           → Match, StudySession, Room, User, Subject …
    └── widgets/          → LoadingIndicator, ErrorView, StudyMatchLogo

assets/
├── hsh_logo.png              → HSH-Logo (wird im StudyMatchLogo-Widget genutzt)
├── login_illustration.png    → Illustration auf dem Login-Screen
└── blacklist.json            → Verbotene Begriffe (Chat + E-Mail, synchron mit backend/blacklist.json)
```

## Designsystem

Alle Farben in `core/app_colors.dart` als dynamische statische Getter — wechseln automatisch bei Theme-Änderung:

| Konstante | Light | Dark | Verwendung |
|---|---|---|---|
| `AppColors.primary` | `#6F35D4` | `#F9AB0B` | Buttons, Nav-Indikator, Akzente |
| `AppColors.primaryLight` | `#EDE7FF` | `#2D2100` | Chip-Hintergrund, Icon-Kreise |
| `AppColors.navy` | `#0B1B3A` | `#FFFFFF` | Headlines, Fließtext |
| `AppColors.background` | `#F8F8FB` | `#000000` | Scaffold-Hintergrund |
| `AppColors.cardWhite` | `#FFFFFF` | `#1C1C1E` | Cards, Input-Felder |
| `AppColors.muted` | `#8A8FAB` | `#636366` | Sekundärtexte, inaktive Icons |
| `AppColors.orange` | `#F0441A` | `#F0441A` | Logo-Akzent (unveränderlich) |
| `AppColors.success` | `#27AE60` | `#27AE60` | Gutes Match, bestätigte Termine |
| `AppColors.warning` | `#F39C12` | `#F39C12` | Mäßiges Match |
| `AppColors.error` | `#E74C3C` | `#E74C3C` | Fehlermeldungen |

**Hinweis:** `AppColors`-Werte sind statische Getter (keine Konstanten) — `const`-Konstruktoren, die sie referenzieren, müssen ohne `const` geschrieben werden.

## Dark Mode

Der Dark-Mode-Toggle befindet sich im Profil-Tab (AppBar-Icon).  
Der Zustand wird via `flutter_secure_storage` persistent gespeichert und beim App-Start wiederhergestellt.  
Provider: `isDarkModeProvider` (`StateNotifierProvider<ThemeModeNotifier, bool>`) in `core/theme_provider.dart`.

## State Management

Riverpod (`flutter_riverpod`). Alle Provider in `*_provider.dart`-Dateien neben den jeweiligen Screens.  
Keine Business-Logik in Widgets — immer in Notifier-Klassen.

## Navigation

GoRouter mit `ShellRoute` für die Bottom-Navigation (Matches / Chat / Profil / Termine).  
Tab-Wechsel verwenden direktionale `SlideTransition`-Animationen (links/rechts je nach Tab-Richtung).  
Auth-Guard: Nicht eingeloggte User werden automatisch zu `/login` umgeleitet.  
Chat öffnet als separater Full-Screen-Route außerhalb der Shell.

## Wichtige Hinweise

- **AppColors nicht const:** Da `AppColors` dynamische Getter verwendet, dürfen keine `const`-Konstruktoren mit `AppColors.*` als Argumente verwendet werden.
- **match_id:** `Match.matchId` enthält die UUID des DB-Match-Datensatzes — wird beim Anlegen von Lernterminen benötigt.
- **mounted-Checks:** Alle Notifier prüfen `if (!mounted) return` nach jedem `await`.
- **Provider-Reset:** `AuthNotifier._clearUserData()` invalidiert alle nutzerspezifischen Provider bei Login/Logout — nicht entfernen.
- **Blacklist:** `assets/blacklist.json` muss manuell synchron mit `backend/blacklist.json` gehalten werden — beide Dateien sind identisch aufgebaut.
- **Zeitauswahl:** Alle `showTimePicker`-Aufrufe nutzen `showTimePicker24h()` aus `core/time_picker_utils.dart` für 24h-Format mit deutschen Labels.
