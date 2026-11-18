# TrackMyGym — Functional Specification & Customer Capabilities

> **Product Name:** TrackMyGym (Digital Fitness Center Operating System & Workout Logger)  
> **Target Audience:** Gym Owners, Branch Managers, Front-Desk Staff, Personal Trainers, and Members  
> **Platforms:** Android Tablets & Phones, Windows Desktop, iPads & Chromebooks (Web PWA)  
> **Architecture:** Offline-First Hybrid (100% Data Sovereignty with Optional Cloud Sync)

---

## Comprehensive Platform Feature Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TRACKMYGYM PLATFORM MATRIX                          │
├─────────────────────┬─────────────────────┬─────────────────────────────────┤
│  1. ACCESS & ATTEND │  2. MEMBER & KYC    │  3. DIGITAL ID PASS & QR        │
│  • Dynamic QR Gate  │  • Photo KYC Capture│  • High-Res Member Pass Card    │
│  • Anti-Passback 60m│  • Normalized Phone │  • Dynamic Vector QR Code       │
│  • Live Status Alert│  • PAR-Q Health Form│  • 1-Tap WhatsApp Dispatch      │
│  • Fast Phone Lookup│  • Emergency Contact│  • Live Expiry & Dues Indicator │
├─────────────────────┼─────────────────────┼─────────────────────────────────┤
│  4. LOCKER FLOOR MAP│  5. WORKOUT LOGGER  │  6. FINANCIAL LEDGER & POS      │
│  • Visual Locker Grid│ • Sets, Reps & Kg  │  • Cash vs UPI Daily Audit      │
│  • 1-to-1 Assignment│ • Rest Interval Pop │  • Partial Dues Collection      │
│  • Status Indicators│ • Volume Calculator │  • GST Tax Invoices             │
│  • Deposit Tracking │ • Routine Templates │  • WhatsApp Payment Receipts    │
├─────────────────────┴─────────────────────┴─────────────────────────────────┤
│  7. DATA SOVEREIGNTY & DISASTER RECOVERY                                    │
│  • 100% Offline-First Operation (Local Storage & SharedPreferences)         │
│  • 1-Click Encrypted Full JSON Snapshot (Members, Lockers, Ledger, Logs)    │
│  • SHA-256 Checksum Verification & Pre-Restore Inspection Modal              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Dynamic Access Control & Attendance Gatekeeper

- **Sub-Second Dynamic QR Scan**: Members scan their digital pass at reception or kiosk.
- **Audio-Visual Gatekeeper Status**:
  - **Green (Access Granted):** Active subscription in good standing.
  - **Amber (Warning):** Member has pending dues; front-desk prompted to collect payment.
  - **Red (Access Denied):** Subscription expired or member marked as frozen.
- **Anti-Passback Protection**: Automatically blocks duplicate check-in scans within a 60-minute window.
- **Today's Live Check-in Feed**: Real-time chronological log of attendance with shift tags and timestamps.

---

## 2. Member Enrollment & PAR-Q Health KYC

- **Demographic Intake**: Full name, standardized phone number, gender, date of birth.
- **PAR-Q Medical Screening**: Flags high blood pressure, asthma, and prior joint/spinal injuries to ensure floor safety.
- **Emergency Contact**: Immediate phone numbers for family or physician.
- **Anti-Duplicate Phone Enforcement**: Standardized formatting prevents accidental duplicate member records.

---

## 3. Interactive Visual Locker Grid

- **Visual Map (L-01 to L-40+)**: Bird's-eye view of all lockers on the gym floor.
- **Status Indicators**:
  - *Slate / Grey:* Available for allocation.
  - *Emerald Green:* Currently assigned to an active member.
  - *Amber / Orange:* Overdue key or pending dues.
  - *Red:* Locker undergoing lock repair or maintenance.
- **Security Deposit Ledger**: Tracks refundable locker deposits held in escrow.

---

## 4. In-App Workout Logger (Hevy/Strong Standard)

- **Set & Rep Tracking**: Supports warm-up sets, working sets, drop sets, and failure sets.
- **Live Rest Interval Timer**: Visual countdown dial with quick increment buttons (+30s, +60s, +90s).
- **Volume & Tonnage Calculator**: Computes cumulative kg lifted in real time.
- **Estimated 1-Rep Max (1RM)**: Uses the Epley formula ($1RM = w \times (1 + r / 30)$) to track strength milestones.

---

## 5. Financial Ledger & WhatsApp Invoicing

- **Dual-Channel Reconciliation**: Separate tracking of UPI (Google Pay, PhonePe, Paytm) vs physical cash.
- **Partial Dues Settlement**: Collect installment payments on the fly and update balances.
- **1-Tap WhatsApp Receipt**: Generates formatted, GST-compliant digital receipts and opens WhatsApp directly.

---

## 6. Data Sovereignty & Offline Resilience

- **100% Offline Persistence**: Local storage engine ensures zero interruption during Wi-Fi outages.
- **Disaster Recovery**: 1-click export of an encrypted full-system JSON snapshot.
- **Spreadsheet Sync**: 1-click CSV export of member lists and financial ledgers for Excel or Tally.
