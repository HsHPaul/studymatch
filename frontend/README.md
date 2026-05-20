# StudyMatch – Frontend

Flutter-App (Dart) für die StudyMatch-Plattform.

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
│   ├── api_client.dart   → Dio, JWT-Interceptor, 401-Logout
│   ├── router.dart       → GoRouter, Auth-Guard
│   └── theme.dart        → Material 3
├── features/
│   ├── auth/             → Login, Register, AuthNotifier
│   ├── profile/          → Profil, Fächer, Zeitfenster
│   ├── matching/         → Match-Liste, Detail
│   ├── chat/             → WebSocket-Chat
│   └── sessions/         → Lerntreffen
└── shared/
    ├── models/
    └── widgets/
```
