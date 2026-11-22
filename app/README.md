# Pantry App (Frontend)

Flutter mobile and web frontend for the Household Pantry app ("Pantry").

## Stack & Target Platforms
- **Framework:** Flutter (Dart) with Material 3 design
- **State Management:** Provider
- **Platforms:** Android (APK) and Web (PWA / Safari "Add to Home Screen" on iOS)
- **Language:** English only (no localization overhead)

---

## Getting Started

### 1. Prerequisites
- Flutter SDK 3.19+ (configured with Android & Web tools)
- Chrome (for web development) or Android Studio / Emulator (for mobile)

### 2. Install Dependencies
From the `app/` directory:
```bash
flutter pub get
```

---

## Running the Application

### A. Web (Chrome on fixed port 3000)
Run the web app on port `3000` (matches backend CORS allowed origin):
```bash
flutter run -d chrome --web-port 3000
```

To explicitly configure the backend API URL:
```bash
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### B. Android Emulator
The Android emulator accesses your host machine's `localhost` via the special loopback alias `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### C. Physical Phone (over local Wi-Fi / LAN)
When testing on a real device, connect both your phone and laptop to the same Wi-Fi network and pass your laptop's local LAN IP:
```bash
# Example with laptop IP 192.168.1.50
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000
```
*(Ensure port 8000 is open in your local firewall and backend is bound to `0.0.0.0`).*

---

## Project Structure (SPEC Section 9)
```
lib/
  main.dart            # Root widget, MultiProvider setup, MaterialApp
  app_theme.dart       # Material 3 theme (teal primary, status colors, >=16sp body text)
  router.dart          # Bottom navigation shell (Home, Pantry, Shopping, Household)
  core/
    constants.dart     # Compile-time constants & API URL defaults
    api_client.dart    # Central HTTP client with Bearer auth and JSON error handling
    storage.dart       # FlutterSecureStorage token persistence
  features/
    auth/              # (data/, ui/, state/)
    home/              # (data/, ui/, state/)
    pantry/            # (data/, ui/, state/)
    shopping/          # (data/, ui/, state/)
    household/         # (data/, ui/, state/)
```
