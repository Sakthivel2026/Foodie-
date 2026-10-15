# Foodie Customer Flutter App

A modern, high-performance Swiggy-style food delivery Android application built with **Flutter 3.47+**, **Dart 3.13+**, and **Riverpod**.

---

## 📱 App Overview

Foodie is a customer-facing food delivery mobile application consuming the Node.js/Express/PostgreSQL backend (`foodie_backend`). It features realtime order tracking via Socket.IO, seamless location pin-drop via OpenStreetMap (`flutter_map`), offline persistence with `shared_preferences` and `flutter_secure_storage`, and pluggable payment gateways.

---

## 🛠️ Tech Stack & Key Packages

- **Framework**: Flutter (Android Target)
- **State Management**: Riverpod (`flutter_riverpod` - Notifier & AsyncNotifier)
- **Navigation**: `go_router`
- **Networking**: `dio` (with serialized JWT refresh interceptor & debug logging)
- **Realtime**: `socket_io_client`
- **Storage**: `flutter_secure_storage` (Tokens) & `shared_preferences` (Cart & Cache)
- **Maps**: `flutter_map` with `latlong2` (OpenStreetMap tiles)
- **Formatting**: `intl` (Money formatted strictly as ₹ from integer paise)
- **Testing**: `flutter_test`, `mocktail`

---

## 🏛️ Architecture & Folder Structure

Built using **Feature-First Clean Architecture**:

```
lib/
├── app/
│   ├── app.dart           # MaterialApp entry point
│   ├── router.dart        # GoRouter navigation & auth redirects
│   └── theme.dart         # Material 3 Warm Orange theme (Light & Dark)
├── core/
│   ├── config/            # Env configuration (API_BASE_URL, PAYMENT_MODE)
│   ├── errors/            # Failure mapping from DioException
│   ├── network/           # Dio client, AuthInterceptor, PaymentGateway abstraction
│   ├── storage/          # StorageService (Secure Storage & SharedPreferences)
│   ├── utils/             # Form validation & formatters
│   └── widgets/           # Reusable widgets (LoadingIndicator, ErrorView, EmptyView)
└── features/
    ├── addresses/         # Address list, Add/Edit form, Location Picker (OSM)
    ├── auth/              # Splash, Login, Register screens
    ├── cart/              # Cart notifier with offline persistence
    ├── checkout/          # Checkout summary, Place Order & Payment flow
    ├── orders/            # Live tracking (Socket.IO + 5s polling), Order history, Detail
    ├── profile/           # User profile, address shortcuts, app version, logout
    ├── restaurants/       # Home list (infinite scroll, debounced search), Restaurant detail
    ├── shell/             # Navigation shell bar
    └── splash/            # Splash screen session restoration
```

### Architecture Diagram

```
+-----------------------------------------------------------------------+
|                         Presentation Layer                            |
|     (Screens, Reusable Widgets, Riverpod Notifiers, GoRouter)         |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                           Domain Layer                                |
|         (Entities, Repository Interfaces - Pure Dart)                 |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                            Data Layer                                 |
|   (Models with fromJson/toJson, Dio Data Sources, Repo Implementations)|
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                        External Services                              |
|    (Foodie Express Backend, Socket.IO Server, OpenStreetMap Tiles)    |
+-----------------------------------------------------------------------+
```

---

## 🚀 Setup & Running Instructions

### Prerequisites
- Flutter SDK (3.47.6 or compatible)
- Android Studio / Android SDK Platform-Tools (`adb`)
- Android Emulator (Pixel_7 `emulator-5554`) or Real Android Device

### Environment Flags (`--dart-define`)
- `API_BASE_URL`: Defaults to `http://10.0.2.2:3000` (Android Emulator loopback)
- `PAYMENT_MODE`: Options: `mock` (default) or `razorpay`

### Running on Android Emulator
```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=PAYMENT_MODE=mock
```

### Running on Real Android Phone via USB
1. Connect phone via USB and enable USB Debugging.
2. Port-forward local port 3000 to the device using `adb`:
```powershell
adb reverse tcp:3000 tcp:3000
```
3. Run the Flutter application:
```powershell
flutter run -d <device_id> --dart-define=API_BASE_URL=http://localhost:3000 --dart-define=PAYMENT_MODE=mock
```

---

## 🧪 Testing & Code Quality

Run static analysis:
```powershell
flutter analyze
```

Run test suite:
```powershell
flutter test
```

Build debug APK:
```powershell
flutter build apk --debug
```

---

## 📸 Screenshots

| Home & Explore | Restaurant Detail | Live Order Tracking | My Profile |
| :---: | :---: | :---: | :---: |
| *(Screenshot Placeholder)* | *(Screenshot Placeholder)* | *(Screenshot Placeholder)* | *(Screenshot Placeholder)* |
