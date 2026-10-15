# Foodie - Full Stack Food Delivery Platform

Foodie is a complete food delivery platform consisting of a finished Node.js/Express/PostgreSQL backend service (`foodie_backend`) and a clean architecture Flutter Android customer app (`foodie_app`).

---

## 🏗️ Repository Architecture

- [**`foodie_backend/`**](file:///c:/dev/foodie/foodie_backend/README.md): Node.js, Express, PostgreSQL, Prisma/Knex, Socket.IO realtime server, delivery simulator, Postman collection.
- [**`foodie_app/`**](file:///c:/dev/foodie/foodie_app/README.md): Flutter 3.47+, Dart 3.13+, Riverpod, GoRouter, Dio, Socket.IO Client, OpenStreetMap (`flutter_map`).

---

## 🔄 End-to-End System Flow

```
+------------------+         REST API (HTTP)         +----------------------+
|                  | ------------------------------> |                      |
|                  |   /auth/login, /auth/register   |                      |
|                  |   /restaurants, /addresses      |    foodie_backend    |
|   foodie_app     |   /orders, /payments/create     |    (Node / Express / |
|   (Flutter App)  |   /payments/verify              |      PostgreSQL)     |
|                  | <------------------------------ |                      |
|                  |                                 +----------------------+
|                  |                                            |
|                  |          Realtime Sockets                  |
|                  | <==========================================+
|                  |   'status_updated', 'location_updated'     |
+------------------+   (via Delivery Simulator Engine)          v
                                                         +------------------+
                                                         |    PostgreSQL    |
                                                         |     Database     |
                                                         +------------------+
```

---

## 🚀 Quick Start (Local Development)

### 1. Start Backend & Database
```powershell
cd c:\dev\foodie\foodie_backend
npm install
npm run migrate
npm run seed
npm start
```
*Backend runs on http://localhost:3000.*

### 2. Launch Android App on Emulator
```powershell
cd c:\dev\foodie\foodie_app
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=PAYMENT_MODE=mock
```

---

## 🧪 CI / CD Workflow

Automated testing is configured via GitHub Actions in [.github/workflows/ci.yml](file:///c:/dev/foodie/.github/workflows/ci.yml).
- **Backend Job**: Runs PostgreSQL service container, runs database migrations, executes `npm test`.
- **Flutter Job**: Validates Dart code formatting, executes `flutter analyze`, and runs unit & widget tests via `flutter test`.
