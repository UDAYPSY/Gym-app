# TrackMyGym — Gym Management & Workout Operating System

> **A World-Class, Offline-First Gym Operating System, Access Gatekeeper & Interactive Workout Logger.**  
> Built with Flutter 3.24+ & Dart 3.3+ (Material Design 3) for Mobile, Web, and Desktop.

---

## 🌟 Executive Overview

**TrackMyGym** combines front-desk gym management (memberships, admissions, dues, visual locker grid, dynamic QR access gate, WhatsApp automation) with an in-depth workout logging engine (sets, reps, weights, rest timers, 1RM calculator, total volume tonnage) into a single, cohesive, offline-resilient platform.

---

## 🚀 Key Features

### 1. 🛡️ Access Control & Attendance Kiosk
- **Dynamic QR Code Check-In**: Sub-second verification of member pass.
- **Instant Gatekeeper Verdict**: Green (Active), Red (Expired / Blocked), Amber (Dues Pending warning).
- **Anti-Passback Engine**: Blocks duplicate check-in attempts within 60 minutes to prevent pass sharing.
- **Manual Fast Search**: Look up members instantly by mobile phone or name.

### 2. 👥 Member Onboarding & Medical KYC
- **PAR-Q Health Clearance**: Capture blood pressure, asthma, and injury histories to ensure safety.
- **Anti-Duplicate Phone Enforcement**: Standardized format (`+91`, `0`, spaces stripped).
- **Digital Membership Pass**: High-resolution digital ID card with scannable vector QR code.
- **1-Tap WhatsApp Sharing**: Send digital passes and renewal receipts directly to members via WhatsApp.

### 3. 🔒 Interactive Locker Floor Grid
- **Bird's-Eye Visual Grid**: Real-time status for lockers (L-01 to L-40+).
- **1-to-1 Collision Lock**: Guarantees no locker double-booking.
- **Security Deposit Ledger**: Track refundable locker deposits.

### 4. 🏋️ In-App Workout Logger (Inspired by Hevy & Strong)
- **Compound & Isolation Lift Tracking**: Log warm-up sets, working sets, drop sets, and failure sets.
- **Interactive Rest Interval Timer**: Visual countdown with quick time adjustments (+30s, +60s, +90s).
- **Live Tonnage / Volume Calculator**: Tracks total kg lifted across the entire workout.
- **Routine Presets**: Push/Pull/Legs, Upper/Lower, and Hypertrophy templates.

### 5. 💰 Financial Ledger & GST Tax Invoices
- **Cash vs UPI Dual Audit**: Daily end-of-day reconciliation.
- **Dues Settlement Flow**: Fast partial dues collection.
- **1-Tap WhatsApp Receipts**: Professional digital receipts with GST splits.

### 6. 🛡️ 100% Offline-First Architecture & Data Sovereignty
- **Dual-Execution Local Storage**: Works seamlessly offline without an active internet connection.
- **1-Click Encrypted JSON Backup**: Full snapshot with SHA-256 checksum verification.
- **Pre-Restore Inspection Modal**: Preview item counts before database rehydration.

---

## 📐 Architecture & Technology Stack

| Layer | Component | Description |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.24+ / Dart 3.3+ | Cross-platform UI toolkit (Android, Web, Desktop) |
| **Design** | Material Design 3 | Energetic Dark Fitness Theme with High-Contrast Accents |
| **State & Logic** | Reactive Streaming | Singleton `GymService` with broadcast stream controllers |
| **Storage** | Hybrid Dual-Execution | LocalStorage / SharedPreferences + Firestore sync |
| **CI / CD** | GitHub Actions | Automated Android Release APK build & artifact upload |

---

## 🛠️ Building & Running

### Automated Android APK Build (GitHub Actions)
Every commit pushed to the `main` branch triggers `.github/workflows/build-apk.yml`, compiling the release Android APK and uploading it as a downloadable GitHub Actions artifact.

### Running Locally
```bash
# Clone the repository
git clone https://github.com/UDAYPSY/Gym-app.git
cd Gym-app

# Install dependencies
flutter pub get

# Run on Chrome Web or connected Android device
flutter run -d chrome
```

---

## 📄 License
Proprietary & Confidential. Built for World-Class Gym & Fitness Center Operations.
