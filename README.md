<div align="center">

# 🍔 Foodie

**A full-stack food delivery platform with live order tracking**

Flutter mobile app + Node.js / Express / PostgreSQL backend + real-time updates over Socket.IO

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express-000000?logo=express&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Socket.IO](https://img.shields.io/badge/Socket.IO-010101?logo=socketdotio&logoColor=white)
![Razorpay](https://img.shields.io/badge/Razorpay-0C2451?logo=razorpay&logoColor=white)
![CI](https://img.shields.io/badge/CI-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)

</div>

---

## 📸 Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/splash.png" width="200" alt="Splash"/><br/><sub>Splash</sub></td>
    <td align="center"><img src="docs/screenshots/explore.png" width="200" alt="Explore"/><br/><sub>Explore & filters</sub></td>
    <td align="center"><img src="docs/screenshots/cart.png" width="200" alt="Cart"/><br/><sub>Cart</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/checkout.png" width="200" alt="Checkout"/><br/><sub>Confirm & Pay</sub></td>
    <td align="center"><img src="docs/screenshots/tracking.png" width="200" alt="Live tracking"/><br/><sub>Live order tracking</sub></td>
    <td align="center"><img src="docs/screenshots/profile.png" width="200" alt="Profile"/><br/><sub>Profile</sub></td>
  </tr>
</table>

---

## 📖 About

Foodie covers the full ordering journey: browse restaurants and menus, build a cart, pick a delivery address on a map, pay online, and watch the courier move on the map in real time.

The project has two parts:

| Part | Description |
| --- | --- |
| [`foodie_backend`](./foodie_backend) | REST API and Socket.IO server backed by PostgreSQL |
| [`foodie_app`](./foodie_app) | Flutter customer app for Android and iOS |

---

## ✨ Features

**Authentication and security**
- Register, login, logout, and profile (`/auth/me`)
- 15-minute JWT access tokens with single-use rotating refresh tokens (30 days, stored as SHA-256 hashes)
- Reuse of a refresh token revokes the entire token family
- Dio interceptor that queues requests on `401`, refreshes the token once, and retries

**Restaurants and menu**
- Paginated restaurant list with cuisine filters
- Veg / non-veg indicators, ratings, delivery fee, and ETA
- Menu items grouped by category, plus search across items

**Cart**
- One restaurant at a time, with a warning before replacing the cart
- Persisted across app restarts
- Subtotal, 5% tax, and delivery fee shown, then re-validated by the backend
- Cooking instructions field

**Addresses**
- Create, edit, delete, and set a default address
- Map pin selection with OpenStreetMap (`flutter_map`)
- Per-user address isolation

**Checkout and payments**
- Confirm & Pay screen with address switching through a bottom sheet
- Prices are always recomputed on the server from database records
- Restaurant open status and address ownership are verified before an order is created
- Razorpay integration with HMAC SHA-256 signature verification
- Cart is cleared only after payment is verified
- `PAYMENT_MODE=mock` for local development without a Razorpay account

**Live delivery tracking**
- Order states: `PENDING_PAYMENT` → `PLACED` → `PREPARING` → `OUT_FOR_DELIVERY` → `DELIVERED` (or `CANCELLED`)
- A courier simulator interpolates GPS coordinates between the restaurant and the delivery address
- `location_updated` and `status_updated` events are sent through authorized Socket.IO rooms (`order:<id>`)
- The app animates a bike marker on the map and falls back to polling if the socket drops

---

## 🛠️ Tech Stack

**Backend**
- Node.js, Express 5
- PostgreSQL (`pg` with connection pooling and numeric type parsers)
- Socket.IO 4
- Zod request validation
- JWT authentication
- Razorpay Node SDK
- Helmet, CORS, and rate limiting
- Tests with Node's built-in test runner and Supertest

**Mobile app**
- Flutter and Dart
- Riverpod for state management
- GoRouter for navigation (redirects and shell routes)
- Dio for networking
- `flutter_map` and `latlong2` for maps
- `socket_io_client` for real-time updates
- `flutter_secure_storage` for tokens and `shared_preferences` for cart and cache

**Tooling**
- GitHub Actions: backend tests, `flutter analyze`, and `flutter test`

---

## 🏗️ Architecture

```text
┌──────────────────────┐        HTTPS (REST)        ┌──────────────────────┐
│     Flutter App      │ ─────────────────────────▶ │   Express REST API   │
│  Riverpod · GoRouter │                            │  Zod · JWT · Helmet  │
│  Dio + AuthInterceptor│ ◀───────────────────────── │                      │
└──────────┬───────────┘                            └──────────┬───────────┘
           │                                                   │
           │          WebSocket (Socket.IO rooms)              │  node-pg
           └──────────────────────────────────────────────────▶│
                       order:<id> events                       ▼
                                                    ┌──────────────────────┐
                                                    │      PostgreSQL      │
                                                    └──────────────────────┘
```

The app follows a feature-first clean architecture. Each feature is split into `data`, `domain`, and `presentation` layers.

### Repository structure

```text
foodie/
├── .github/workflows/ci.yml        # CI: backend tests + Flutter analyze & tests
├── foodie_backend/
│   ├── sql/                        # SQL migrations (001_users … 006_payments)
│   ├── src/
│   │   ├── config/                 # DB pool and type parsers
│   │   ├── controllers/            # Auth, Restaurants, Addresses, Orders, Payments
│   │   ├── middleware/             # JWT auth, Zod validator
│   │   ├── routes/                 # Express routes
│   │   ├── scripts/                # migrate.js, seed.js, setupTestDb.js
│   │   ├── services/               # delivery.simulator.js
│   │   ├── socket.js               # Socket.IO auth and events
│   │   ├── app.js                  # Express config
│   │   └── server.js               # HTTP + Socket server (port 3000)
│   ├── tests/                      # Integration tests
│   └── docs/                       # Postman collection
└── foodie_app/
    ├── lib/
    │   ├── app/                    # Entry point, router, theme
    │   ├── core/                   # Network, storage, config, errors
    │   └── features/               # auth, restaurants, cart, addresses,
    │                               # checkout, orders, profile, shell, splash
    └── test/                       # Unit and widget tests
```

---

## 🔌 API Overview

| Area | Endpoints |
| --- | --- |
| Auth | `POST /auth/register` · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `GET /auth/me` |
| Restaurants | `GET /restaurants?page=1&limit=10` · `GET /restaurants/:id` · `GET /restaurants/:id/menu` · `GET /restaurants/items` |
| Addresses | `GET /addresses` · `POST /addresses` · `PUT /addresses/:id` · `DELETE /addresses/:id` |
| Orders | `POST /orders` · order history and details |
| Payments | `POST /payments/create` · `POST /payments/verify` |

A Postman collection is available in [`foodie_backend/docs`](./foodie_backend/docs).

### Real-time events

| Event | Direction | Description |
| --- | --- | --- |
| `location_updated` | server → client | New courier coordinates for an order |
| `status_updated` | server → client | Order status changed |

Clients join the `order:<id>` room, and the server only allows the order's owner to join.

---

## 🚀 Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL 13+
- Flutter SDK (stable) and an Android emulator or device
- *(Optional)* A Razorpay account for live payments

### 1. Backend

```bash
cd foodie_backend
npm install
```

Create a `.env` file (adjust names to match your `src/config`):

```env
PORT=3000
DATABASE_URL=postgres://user:password@localhost:5432/foodie
JWT_SECRET=change_me
PAYMENT_MODE=mock          # mock | live
RAZORPAY_KEY_ID=
RAZORPAY_KEY_SECRET=
```

Then run:

```bash
npm run db:init     # run migrations
npm run db:seed     # seed restaurants, menu items, and test accounts
npm run dev         # start the server with nodemon on http://localhost:3000
```

### 2. Mobile app

```bash
cd foodie_app
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=PAYMENT_MODE=mock
```

> `10.0.2.2` is how the Android emulator reaches `localhost` on your machine. On a physical device, use your computer's LAN IP instead.

---

## 🧪 Testing

```bash
# Backend (integration tests)
cd foodie_backend
npm test

# Flutter (unit and widget tests + static analysis)
cd foodie_app
flutter analyze
flutter test
```

| Suite | Result |
| --- | --- |
| Backend integration tests | 21 / 21 passing |
| Flutter unit and widget tests | 27 / 27 passing |
| `flutter analyze` | 0 issues |

All checks also run on every push through GitHub Actions.

---

## 🗺️ Roadmap

- [ ] Razorpay webhook (`payment.captured`) as a backup confirmation path
- [ ] Idempotency keys for order creation and payment verification
- [ ] Automatic expiry of stale `PENDING_PAYMENT` orders
- [ ] Push notifications (FCM) for order status changes
- [ ] Restaurant dashboard to move orders to `PREPARING`
- [ ] Order cancellation and refund flow
- [ ] Serviceable-radius check and distance-based delivery fee and ETA
- [ ] Production map tiles and geocoding provider
- [ ] Migration tracking table (`schema_migrations`)
- [ ] Structured logging and error monitoring

---

## 🤝 Contributing

Contributions and suggestions are welcome. Open an issue to discuss a change, then submit a pull request. Please make sure `npm test`, `flutter analyze`, and `flutter test` pass first.

---

## 👤 Author

**Sakthivel**

- GitHub: [@your-username](https://github.com/your-username)
- LinkedIn: [your-profile](https://www.linkedin.com/in/your-profile)

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
