# EventAudio App

Flutter mobile app for visitors at events — multi-channel audio streaming via WebRTC/mediasoup SFU.

**Package:** `it.eventaudio.app`
**Platform:** Android (primary), iOS
**Backend:** [ecologicaleaving/EventAudio](https://github.com/ecologicaleaving/EventAudio)

## Setup locale

### Prerequisiti

- Flutter SDK >= 3.10.4 (channel stable)
- Android SDK / Android Studio
- Java 17+

### Installazione

```bash
# 1. Clona la repo
git clone https://github.com/ecologicaleaving/eventaudio-app.git
cd eventaudio-app

# 2. Installa dipendenze
flutter pub get

# 3. Verifica setup
flutter doctor
flutter analyze
```

### Build APK debug

```bash
flutter build apk --debug --target-platform android-arm64
# APK: build/app/outputs/flutter-apk/app-debug.apk
```

### Run su emulatore/dispositivo

```bash
flutter run
```

## Struttura

```
lib/
  main.dart                    # Entry point, DI BLoC providers
  core/
    theme/app_theme.dart       # Design system (dark theme, brand colors)
    utils/
      logger.dart              # Structured logger
      shared_prefs_helper.dart # Persistent preferences (anonymous visitor)
      constants.dart           # App constants
    models/
      channel_model.dart       # Audio channel
      event_model.dart         # Event with channels
  features/
    channels/                  # Channel list (home screen)
      bloc/                    # ChannelBloc
      screens/channel_list_screen.dart
    player/                    # Audio player (WebRTC)
      bloc/                    # PlayerBloc
      screens/player_screen.dart
    qr_scan/                   # QR code scanner
      screens/qr_scan_screen.dart
packages/
  mediasoup_client_flutter/    # Patched local version (null-safety fix)
```

## Dipendenze chiave

| Package | Versione | Uso |
|---|---|---|
| `flutter_bloc` | ^8.1.3 | State management |
| `flutter_webrtc` | ^0.12.0 | WebRTC audio |
| `mediasoup_client_flutter` | local patch | SFU client |
| `socket_io_client` | ^2.0.3+1 | Signaling |
| `mobile_scanner` | ^5.0.0 | QR scanner |
| `flutter_foreground_task` | ^6.0.0+1 | Background audio |
| `permission_handler` | ^11.0.1 | Mic/audio permissions |

## CI/CD

Ogni push su `feature/*` e ogni PR triggera `.github/workflows/build.yml`:
- `flutter analyze` + `flutter test`
- Build APK debug (arm64)
- Deploy su `https://apps.8020solutions.org/downloads/test/`
- Comment PR con link APK

## Workflow

1. Visitor scansiona QR code evento
2. App mostra canali audio disponibili
3. Visitor sceglie il canale (es. lingua)
4. App connette via WebRTC/mediasoup SFU
5. Audio in streaming in background (foreground service)

## Note mediasoup patch

`packages/mediasoup_client_flutter` e' una copia patchata del pacchetto originale,
necessaria per la compatibilita' con `webrtc_interface: 1.3.0` (il campo `cname`
e' `String?` nelle versioni recenti). Non usare la versione pub.dev.

