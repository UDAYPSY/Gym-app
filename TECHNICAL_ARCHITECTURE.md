# TrackMyGym — Technical Architecture & Engineering Blueprint

> **System Name:** TrackMyGym (Digital Fitness Center Operating System & Workout Logger)  
> **Core Framework:** Flutter 3.24+ / Dart 3.3+ (Material Design 3)  
> **Architecture Pattern:** Hybrid Offline-First Reactive Streaming with Conditional Compilation  
> **Production Target:** Android APK / AAB, Web (PWA CanvasKit), Desktop  
> **Repository:** https://github.com/UDAYPSY/Gym-app.git

---

## 1. System Architecture Overview

TrackMyGym employs a **Dual-Execution, Offline-First Reactive Architecture**. The application is designed to function completely offline on local device storage while seamlessly connecting to Cloud Firestore when network connectivity is available.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       APPLICATION ARCHITECTURE LAYERS                       │
└─────────────────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────────────┐
  │                           PRESENTATION LAYER                            │
  │  • Dashboard Screen      • Member Directory & KYC  • Access Gate Kiosk  │
  │  • Locker Visual Grid    • Interactive Workout Log • Financial Ledger   │
  │  • Digital Gym Pass      • Rest Interval Timer     • Tools & Backups    │
  └────────────────────────────────────┬────────────────────────────────────┘
                                       │ Watches Streams / Dispatches Actions
                                       ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                     SERVICE & STATE MANAGEMENT LAYER                    │
  │  • GymService (Singleton, Reactive StreamControllers)                   │
  │  • DisasterRecoveryService (SHA-256 JSON Snapshot Engine)               │
  │  • FileExportService (Conditional: Web Blob vs Mobile IO)               │
  │  • ThemeService (Persistent Dark/Light Mode Provider)                   │
  └──────────────────┬───────────────────────────────────┬──────────────────┘
                     │                                   │
      Offline Branch │ Local Persistence                 │ Cloud Sync
                     ▼                                   ▼
  ┌─────────────────────────────────────┐  ┌────────────────────────────────┐
  │        OFFLINE STORAGE LAYER        │  │       CLOUD FIREBASE LAYER     │
  │ • LocalStorageService (Conditional) │  │ • Cloud Firestore (NoSQL)     │
  │   - Web: window.localStorage        │  │ • Atomic Batch Operations      │
  │   - IO: SharedPreferences / File    │  │ • Firestore Security Rules     │
  │ • JSON Disaster Recovery Snapshots  │  │ • Firebase Authentication      │
  └─────────────────────────────────────┘  └────────────────────────────────┘
```

---

## 2. Technology Stack & Key Dependencies

| Component | Library / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | `flutter` (Dart SDK `>=3.3.0 <4.0.0`) | Cross-platform core framework |
| **Cloud Database** | `cloud_firestore: ^5.4.4` | Real-time multi-device cloud synchronization |
| **Cloud Auth** | `firebase_auth: ^5.3.1` | User authentication & role management |
| **QR Code Engine** | `qr_flutter: ^4.1.0` | Vector rendering of dynamic membership pass QR codes |
| **Media Capture** | `image_picker: ^1.1.2` | Camera & gallery photo capture for member KYC |
| **Image Compression**| `flutter_image_compress: ^2.3.0` | Client-side compression for embedded photo tokens |
| **Date & Locale** | `intl: ^0.19.0` | Currency, date, and Indian locale formatting |
| **External Intent** | `url_launcher: ^6.3.0` | WhatsApp URI deep-linking (`https://wa.me/...`) |
| **Integrity Checks** | `crypto: ^3.0.6` | SHA-256 checksums for backup verification |
| **Sharing** | `share_plus: ^10.1.2` | Native sharing of exported CSV/JSON files |
| **Biometrics** | `local_auth: ^2.3.0` | Fingerprint / face unlock for desk staff login |

---

## 3. Entity-Relationship Data Model

```
                    ┌─────────────────┐
                    │  BranchProfile  │
                    └────────┬────────┘
                             │ 1-to-N
                             ▼
                    ┌─────────────────┐
                    │    GymMember    │◄──────────────┐
                    └──┬────────────┬─┘               │
       1-to-1          │            │ 1-to-N          │
  ┌────────────────────┘            ▼                 │
  ▼                        ┌─────────────────┐        │
┌────────┐                 │ AttendanceRecord│        │
│ Locker │                 └─────────────────┘        │
└────────┘                                            │
  ▲                                                   │
  │ 1-to-N                                            │
┌────────────────────────┐                            │
│  FinancialTransaction  ├────────────────────────────┘
└────────────────────────┘
  ▲
  │ 1-to-N
┌────────────────────────┐
│     WorkoutSession     │
└──────────┬─────────────┘
           │ 1-to-N
           ▼
┌────────────────────────┐
│      ExerciseLog       │
└──────────┬─────────────┘
           │ 1-to-N
           ▼
┌────────────────────────┐
│       WorkoutSet       │
└────────────────────────┘
```

---

## 4. CI/CD & Automated Deployment Pipeline

The repository includes `.github/workflows/build-apk.yml`, which:
1. Configures an Ubuntu runner with Java JDK 17 and Flutter 3.24.x stable.
2. Runs static code analysis and unit tests (`flutter test`).
3. Compiles the Android Release APK (`flutter build apk --release`).
4. Uploads the generated APK as an artifact with a 30-day retention period.
