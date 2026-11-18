# TrackMyGym — AI Technical Manual & Developer Instructions

> **Audience:** Future AI Agents and Human Software Engineers modifying or extending TrackMyGym.  
> **Repository:** https://github.com/UDAYPSY/Gym-app.git  
> **Parent Workspace:** `D:\Tutorial\Gym Tracking App`

---

## 1. Cardinal Engineering Principles

1. **Isolation from Library App:**  
   Never modify or import from `../Library-app`. All assets, models, and code must reside strictly within `Gym Tracking App` (`Gym-app`).
2. **Offline-First Data Sovereignty:**  
   Every state change must be applied to the in-memory cache and persisted to `LocalStorageService` immediately. The app must never fail or block user actions when network connectivity is lost.
3. **Anti-Passback Integrity:**  
   Attendance logic enforces a 60-minute duplicate check-in window. Modifications to `recordCheckIn` in `GymService` must preserve this security guarantee.
4. **Conditional Compilation Boundaries:**  
   Platform-specific imports (e.g. `dart:html` vs `dart:io`) must always be routed through stub patterns (`file_export_service.dart`, `local_storage_service.dart`). Do not introduce direct platform dependencies in business logic.

---

## 2. Directory Layout & Key File Map

```
Gym Tracking App/
├── .github/workflows/
│   └── build-apk.yml               # Automated Android APK CI/CD pipeline
├── android/                        # Native Android shell and build gradle configs
├── web/                            # Web PWA manifest and HTML entrypoint
├── lib/
│   ├── constants/
│   │   └── app_constants.dart      # Color palette, shift definitions, muscle groups
│   ├── models/
│   │   └── gym_models.dart         # Core domain entities with JSON serialization
│   ├── services/
│   │   ├── gym_service.dart        # Reactive singleton state management
│   │   ├── disaster_recovery_service.dart # SHA-256 backup & restore engine
│   │   ├── file_export_service.dart # Cross-platform CSV/JSON exporter
│   │   ├── local_storage_service.dart # Dual-execution offline storage
│   │   └── theme_service.dart      # Dark fitness / Light theme provider
│   ├── widgets/
│   │   ├── digital_gym_pass.dart   # Vector QR membership pass with WhatsApp dispatch
│   │   ├── locker_tile.dart        # Interactive visual locker box
│   │   └── rest_timer_dialog.dart  # Animated countdown timer for workouts
│   ├── screens/
│   │   ├── main_hub_screen.dart    # Root adaptive shell with navigation
│   │   ├── dashboard_screen.dart   # Live revenue, occupancy, and dues warnings
│   │   ├── members_screen.dart     # Member directory & PAR-Q admission wizard
│   │   ├── attendance_screen.dart  # Dynamic QR Gatekeeper kiosk & live feed
│   │   ├── lockers_screen.dart     # Interactive visual locker grid
│   │   ├── workouts_screen.dart    # Set/rep logger, volume tracker, & rest timer
│   │   ├── payments_screen.dart    # Cash vs UPI ledger & WhatsApp receipts
│   │   ├── leads_screen.dart       # Walk-in CRM pipeline & WhatsApp nudges
│   │   └── tools_screen.dart       # Backup JSON snapshot, CSV export, & settings
│   └── main.dart                   # Application bootstrap
└── test/
    └── gym_service_test.dart       # Unit test suite for core operations
```

---

## 3. Extending the Application

### Adding a New Exercise or Muscle Group
Edit `lib/constants/app_constants.dart` under `MuscleGroups.all`. Then update preset routines in `lib/screens/workouts_screen.dart`.

### Modifying Membership Plans
Update `_seedInitialData()` in `lib/services/gym_service.dart`. When adding custom plans via the UI, ensure `MembershipPlan.fromJson()` handles optional fields gracefully.
