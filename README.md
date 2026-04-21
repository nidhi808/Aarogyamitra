# Aarogyamitra (आरोग्यमित्र) 🩺

**Aarogyamitra** is an offline-first, voice-powered health assistant designed to bridge the gap between complex government healthcare schemes and the citizens of Maharashtra. It provides a purely local, private, and accessible way for users to discover medical benefits and find nearby hospitals using only their voice in **Hindi** or **Marathi**.

---

## 🚀 Key Features

- **100% Offline-First**: No internet connection required. All data (schemes, hospitals, doctors) is stored locally in CSV files.
- **Voice-Powered Interaction**: Full conversational flow using the device's native Speech-to-Text (STT) and Text-to-Speech (TTS) engines.
- **Smart Scheme Matching**: Automatically recommends the best eligible health schemes (like MJPJAY, Ayushman Bharat, RBSK) based on user details (BPL status, cards, age, symptoms).
- **Nearby Hospital Locator**: Uses local geolocation to find the nearest health facility and shows its distance.
- **Unified Health Summary**: Generates a beautiful "Health Summary Card" at the end of each session containing:
  - Patient Details (Name, Age, Symptoms)
  - Recommended Doctor & Specialty
  - Eligible Scheme & Required Documents
  - Nearest Hospital Information
- **Google-Free Native Engine**: Explicitly favors non-Google system engines (like Samsung TTS) to ensure maximum privacy and reliance on local hardware.

---

## 🛠️ Technology Stack

- **Core**: Flutter / Dart
- **Design System**: *Tactile Earth Narrative* (Neem & Haldi themed)
- **Data Layer**: Local CSV parsing (doctors, hospitals, schemes)
- **Speech**: `speech_to_text` (Native Dictation Mode) & `flutter_tts` (System Engine Discovery)
- **Storage**: `shared_preferences` & `sqflite` for health history

---

## 📂 Project Structure

```text
lib/
├── models/             # Data models (Scheme, Hospital, Doctor, etc.)
├── screens/            # UI Screens (Home, Result, Voice Consultation)
├── services/           # Business logic (CSV Loader, Speech, TTS, Matching Engine)
└── main.dart           # App entry point
assets/
└── data/               # Local CSV and JSON knowledge base
```

---

## ⚙️ Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-repo/aarogyamitra.git
   ```
2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```
3. **Download Language Packs**:
   - For offline functionality, ensure **Hindi** and **Marathi** language packs are downloaded in your Android system's *Speech Recognition & Synthesis* settings.
4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📝 Important Notes for Developers

### "Google-Free" Policy
The app is strictly designed to avoid dependency on Google Cloud.
- **Fonts**: All UI components use system-default fonts to avoid network font calls.
- **STT**: Uses `onDevice: true` to prevent cloud audio processing.
- **TTS**: Selects the first available non-Google engine (e.g., Samsung) if found on the device.

### Data Customization
You can update the medical knowledge by modifying the CSV files in `assets/data/`:
- `schemes.csv`: Add or update eligibility rules and benefits.
- `hospitals.csv`: List of government-empanelled hospitals.
- `doctors.csv`: List of specialized doctors and their specialties.

---

## 🌍 Language Support
- **Hindi (हिन्दी)**
- **Marathi (मराठी)**

---

## 🙏 Credits
Developed as a tool for ASHA workers and rural citizens to simplify access to healthcare in India.

---