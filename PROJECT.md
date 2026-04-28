# EventAudio App — PROJECT.md

## Project Info

| Campo | Valore |
|---|---|
| **Nome** | EventAudio App |
| **Tipo** | Flutter mobile app (Android/iOS) |
| **Package** | `it.eventaudio.app` |
| **Versione** | 0.1.0 |
| **Repo** | `ecologicaleaving/eventaudio-app` |
| **Repo backend** | `ecologicaleaving/EventAudio` |
| **Stack** | Flutter 3.10+, Dart 3.10+, flutter_bloc, WebRTC/mediasoup |

## Deployment

| Ambiente | URL APK | Branch |
|---|---|---|
| Test | `https://apps.8020solutions.org/downloads/test/` | `feature/*` / PR |
| Production | GitHub Releases | `master` |

- CI: `.github/workflows/build.yml` — build APK debug + deploy su ogni PR/push
- Secrets richiesti: `VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`

## Repository

```
lib/
  main.dart                    # Entry point, MultiBlocProvider
  core/
    theme/app_theme.dart       # Design system dark (riusato da StageConnect)
    utils/
      logger.dart              # Structured logger
      shared_prefs_helper.dart # Persistent prefs — visitatore anonimo (no nickname)
      constants.dart           # AppConstants, NetworkConstants, ChannelConstants
    models/
      channel_model.dart       # Audio channel
      event_model.dart         # Event con channels
    services/
      webrtc_service.dart      # Consumer-only WebRTC/mediasoup (issue-2)
      audio_service.dart       # Playback-only audio service (issue-2)
      foreground_service_manager.dart  # Background audio Android/iOS (issue-2)
  features/
    channels/                  # Home screen — lista canali
      bloc/                    # ChannelBloc/Event/State
      screens/channel_list_screen.dart
    player/                    # Audio player (WebRTC)
      bloc/                    # PlayerBloc/Event/State — wired to WebRtcService
      screens/player_screen.dart
    qr_scan/
      screens/qr_scan_screen.dart  # Placeholder — scanner in issue-4
packages/
  mediasoup_client_flutter/    # Patch locale (null-safety fix)
.github/workflows/build.yml    # CI APK debug
```

## Architecture

- **State management:** flutter_bloc (BlocProvider, BlocBuilder)
- **Audio:** WebRTC via flutter_webrtc + mediasoup SFU client (issue-2)
- **Signaling:** socket_io_client (issue-2)
- **Visitor:** anonimo — nessun nickname, identificato da device UUID
- **Entry flow:** QR scan → lista canali → player (foreground service)

## Dependency Overrides (mediasoup patch)

```yaml
dependency_overrides:
  webrtc_interface: 1.3.0
  dart_webrtc: 1.6.0
  mediasoup_client_flutter:
    path: packages/mediasoup_client_flutter
```

## Backlog

| Issue | Titolo | Stato |
|---|---|---|
| #1 | Bootstrap progetto Flutter + scaffold struttura | Done |
| #2 | Core audio engine — WebRtcService consumer-only + background audio | In Progress |
| #3 | Background audio (flutter_foreground_task) | Todo |
| #4 | Android permissions + deep link QR | Todo |

## Note Tecniche

- `mediasoup_client_flutter` path locale — non usare versione pub.dev
- `analysis_options.yaml` esclude `packages/` dall'analisi (lint pre-existing nel patch)
- Visitatore anonimo: nessun setup nickname, identificato da UUID persistente (`device_id`)
- `AppConstants.wsUrl` → produzione: `https://eventaudio.8020solutions.org`
