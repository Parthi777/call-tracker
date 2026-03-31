# SalesTrack — Executive Call Recorder & Master Dashboard

Flutter mobile app (Android) + Flutter Web master dashboard for tracking executive sales/service calls.
Google Drive auto-upload per executive, real-time KPI sync to a central web console.

---

## Project Architecture

```
salestrack/
├── CLAUDE.md
├── mobile_app/          # Flutter Android — call recorder per executive
│   ├── android/         # Native Android permissions + foreground service
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/        # DI, routing, constants, theme
│   │   ├── features/
│   │   │   ├── auth/            # Executive login (PIN / biometric)
│   │   │   ├── call_recorder/   # Record + metadata capture
│   │   │   ├── drive_upload/    # Google Drive sync per executive folder
│   │   │   └── dashboard/       # Local KPI summary for executive
│   │   └── shared/      # Common widgets, models, utils
│   └── pubspec.yaml
│
├── web_app/             # Flutter Web — master admin dashboard
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/            # Admin login
│   │   │   ├── executives/      # Manage executive list
│   │   │   ├── reports/         # KPI cards, call logs, filters
│   │   │   ├── recordings/      # Browse & play recordings from Drive
│   │   │   └── analytics/       # Charts, trends, exports
│   │   └── shared/
│   └── pubspec.yaml
│
├── backend/             # Dart Shelf API (or Firebase Functions)
│   ├── lib/
│   │   ├── routes/
│   │   ├── models/
│   │   └── services/    # Firestore, Drive API, auth
│   └── pubspec.yaml
│
└── shared_models/       # Dart package — models shared across apps
    └── lib/
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Android), Dart |
| Web app | Flutter Web, Dart |
| IDE | Antigravity IDE |
| Backend | Firebase (Firestore + Functions) or Dart Shelf |
| Storage | Google Drive API v3 (per-executive folders) |
| Auth | Firebase Auth + Google Sign-In |
| State mgmt | Riverpod (both apps) |
| Local DB | Hive (mobile offline queue) |
| Charts | fl_chart |
| Call recording | flutter_phone_state + native Android AudioRecord |

---

## Commands

```bash
# Mobile app
cd mobile_app && flutter run -d android
cd mobile_app && flutter build apk --release
cd mobile_app && flutter test
cd mobile_app && flutter analyze

# Web app
cd web_app && flutter run -d chrome
cd web_app && flutter build web --release
cd web_app && flutter test
cd web_app && flutter analyze

# Shared models package
cd shared_models && dart pub get && dart analyze

# Backend (if Dart Shelf)
cd backend && dart run bin/server.dart
cd backend && dart test
```

---

## Core Features

### Mobile App (Android — Executive)

- **Call Recording** — auto-record incoming & outgoing calls via foreground service
- **Metadata Capture** — caller ID, direction (IN/OUT), duration, timestamp, executive ID
- **Offline Queue** — Hive local store; retry upload when network restores
- **Google Drive Upload** — folder path: `SalesTrack/{ExecutiveName}/{YYYY-MM}/{recording.mp3}`
- **Call Log Sync** — push call metadata JSON to Firestore after each call
- **Executive KPI Card** — local summary: total calls today, avg duration, missed calls
- **Permissions** — `RECORD_AUDIO`, `READ_CALL_LOG`, `FOREGROUND_SERVICE`, `READ_PHONE_STATE`

### Web App (Admin — Master Dashboard)

- **Executive Management** — add/edit/deactivate executives, assign Drive folder
- **KPI Cards** — total calls, incoming/outgoing ratio, avg duration, missed, talk time
- **Call Log Table** — filterable by executive, date range, call type, duration
- **Recording Player** — stream audio directly from Google Drive
- **Analytics Charts** — daily/weekly trends, executive comparison (fl_chart)
- **Export** — CSV/Excel download of filtered call data
- **Real-time Sync** — Firestore listeners for live KPI updates

---

## Data Models

All models live in `shared_models/lib/`. Always import from there — never duplicate.

```dart
// Key models to implement first:
// CallRecord     — id, executiveId, direction, duration, timestamp, driveFileId, status
// Executive      — id, name, phone, driveFolder, isActive, createdAt
// KpiSnapshot    — executiveId, date, totalCalls, incoming, outgoing, missed, avgDuration
// UploadJob      — recordingPath, callRecordId, status, retryCount
```

---

## Code Style

- Dart: follow `flutter analyze` with zero warnings — treat warnings as errors
- Use `freezed` for immutable models with `copyWith`, `fromJson`, `toJson`
- Use `riverpod` (code gen) for all state — no `setState` outside widgets
- Folder per feature: `feature/data/`, `feature/domain/`, `feature/presentation/`
- File names: `snake_case.dart`; class names: `PascalCase`
- No `dynamic` types — always explicit
- All async functions use `AsyncValue` from Riverpod, never raw `Future` in UI

---

## Android-Specific Rules

- Call recording requires `READ_PHONE_STATE` + `RECORD_AUDIO` at runtime — always request before starting recorder
- Use a **foreground service** for recording — never background; Android 10+ will kill background audio
- Target SDK 34 minimum; check `android/app/build.gradle` before adding native code
- Recording format: AAC/MP4 (better compression than WAV for Drive storage)
- Test on physical device — emulator cannot simulate incoming calls

---

## Google Drive Integration

- Each executive gets one folder: create on first login if not exists
- Use service account OAuth2 for backend uploads; device uploads use executive's Google account
- Drive folder ID stored in `Executive.driveFolder` in Firestore
- Upload metadata (file name, duration, call direction) as Drive file description
- File naming: `{YYYYMMDD_HHMMSS}_{IN|OUT}_{CallerNumber}.mp4`

---

## Firestore Structure

```
/executives/{executiveId}
/calls/{callId}           — full CallRecord
/kpi_daily/{executiveId}_{date}  — KpiSnapshot (updated by Cloud Function)
/upload_queue/{jobId}     — pending Drive uploads (mobile writes, backend processes)
```

---

## KPI Definitions (implement exactly as below)

| KPI | Definition |
|---|---|
| Total Calls | All recorded calls in period |
| Incoming | `direction == "IN"` |
| Outgoing | `direction == "OUT"` |
| Missed | Duration < 5 seconds AND direction == "IN" |
| Avg Duration | Sum of durations / Total calls (excluding missed) |
| Talk Time | Sum of all call durations |
| Unique Contacts | Distinct phone numbers |
| Peak Hour | Hour-of-day with most calls |

---

## Critical Rules

- NEVER store Google OAuth tokens in plain SharedPreferences — use `flutter_secure_storage`
- NEVER start recording without explicit runtime permission check
- NEVER upload to Drive synchronously on the main thread — always queue and background process
- NEVER commit `google-services.json`, `.env`, `service_account.json` to Git
- Always test offline→online upload resume — it is a core business requirement
- The web dashboard MUST work on Chrome desktop minimum; mobile web is optional

---

## Environment Setup

```
# Required files (not committed — ask team lead)
mobile_app/android/app/google-services.json
web_app/web/firebase-config.js
backend/.env   # GOOGLE_SERVICE_ACCOUNT_JSON, FIREBASE_PROJECT_ID
```

---

## Development Phases

Work in this order. Do not skip phases.

1. **Phase 1 — Foundation**: shared_models package, Firebase project setup, auth (both apps)
2. **Phase 2 — Recording Core**: Android foreground service, call detection, local Hive queue
3. **Phase 3 — Drive Sync**: upload worker, folder creation, retry logic
4. **Phase 4 — Firestore Sync**: call metadata write, Cloud Function for KPI aggregation
5. **Phase 5 — Web Dashboard**: KPI cards, call log table, executive management
6. **Phase 6 — Analytics**: charts, date filters, CSV export
7. **Phase 7 — Polish**: error states, loading skeletons, offline banners, APK build

---

## Testing Requirements

- Unit test all KPI calculation logic in `shared_models`
- Widget test KPI cards with mock data
- Integration test: record a call → verify Hive entry → verify Drive upload → verify Firestore sync
- Run `flutter analyze` and `flutter test` before every PR

---

## See Also

- `docs/architecture.md` — sequence diagrams for call flow and upload pipeline
- `docs/permissions.md` — Android permission request flow
- `docs/drive_structure.md` — Google Drive folder hierarchy spec
- `docs/kpi_spec.md` — detailed KPI formula reference
