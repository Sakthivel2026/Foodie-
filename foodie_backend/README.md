# Foodie Backend API 🍕🚗

Production-grade, asynchronous Express 5 & Node.js backend for the **Foodie** food delivery web & mobile application.

---

## 🛠 Features & Architecture

- **Security & Hardening**:
  - `helmet` security headers.
  - Rate limiting on `/auth/login` and `/auth/register` endpoints.
  - JWT authentication (15-minute access token lifespan).
  - SHA-256 hashed refresh tokens with automatic token rotation and revocation checks.
  - Zod validation for request body, query, and params.
- **Database & Data Integrity**:
  - Raw SQL with `pg` connection pooling (No ORM overhead).
  - Clean migration system (`npm run db:init`) executing SQL scripts in alphabetical order.
  - Full transactional safety (PostgreSQL `BEGIN` / `COMMIT` / `ROLLBACK`) for multi-step order placement and payment processing.
  - Money represented exclusively as integer paise (`_paise`).
- **Realtime & Delivery Simulator**:
  - Socket.IO server integrated for order tracking.
  - Room authorization ensuring users can only subscribe to their own orders (`order:<order_id>`).
  - Automated delivery simulator emitting `status_updated` and `location_updated` (interpolated GPS coordinates) from restaurant to delivery address.
- **Razorpay Integration**:
  - Dual payment mode support (`PAYMENT_MODE=mock` or `PAYMENT_MODE=razorpay`).
  - Secure HMAC SHA-256 signature verification with `crypto.timingSafeEqual`.

---

## 📋 System Requirements & Setup (Windows PowerShell)

### Prerequisites
- Node.js `v20.x` or higher (Tested on Node `v24.12.0`).
- PostgreSQL running locally on port `5432` with database `foodie` and test database `foodie_test`.

### 1. Environment Configuration
Copy `.env.example` to `.env`:
```powershell
Copy-Item .env.example .env
```
Ensure your local PostgreSQL password and credentials match `.env`:
```env
PORT=3000
DATABASE_URL="postgresql://postgres:1234@localhost:5432/foodie"
DATABASE_URL_TEST="postgresql://postgres:1234@localhost:5432/foodie_test"
JWT_SECRET=super_secret_jwt_key_foodie
ADMIN_KEY=super_secret_admin_key_123
PAYMENT_MODE=mock
RAZORPAY_KEY_ID=mock_key_id
RAZORPAY_KEY_SECRET=mock_secret
```

### 2. Database Initialization & Seeding
Run migrations and seed default data:
```powershell
npm run db:init
npm run db:seed
```

### 3. Running the Server
Start the dev server with nodemon:
```powershell
npm run dev
```

### 4. Running Automated Tests
Run setup for the test database and execute the full test suite:
```powershell
npm test
```

---

## 📜 Available NPM Scripts

| Script | Command | Purpose |
| :--- | :--- | :--- |
| `npm run dev` | `nodemon src/server.js` | Starts HTTP & Socket.IO server with auto-reload |
| `npm run db:init` | `node src/scripts/migrate.js` | Runs all `.sql` migrations in `sql/` in alphabetical order |
| `npm run db:seed` | `node src/scripts/seed.js` | Idempotently seeds 12 restaurants & 96 menu items |
| `npm run test:setup`| `node src/scripts/setupTestDb.js` | Ensures `foodie_test` database exists and runs migrations |
| `npm test` | `node src/scripts/setupTestDb.js && cross-env ...` | Runs 21+ automated tests against `foodie_test` database |

---

## 🔀 Order Lifecycle Flow

```
[ POST /orders ] -> PENDING_PAYMENT / PENDING
                          │
                [ POST /payments/create ] -> Generates Razorpay/Mock Order ID
                          │
                [ POST /payments/verify ] -> Verifies HMAC SHA-256 signature
                          │
                 (Signature Verified)
                          │
                          ▼
            Order Status -> PLACED / Payment Status -> PAID
                          │
       ┌──────────────────┴──────────────────┐
       ▼                                     ▼
[ Socket Room: order:<id> ]       [ Delivery Simulator Started ]
Emits "status_updated"                 │
                                       ├─> Wait (3s) -> status: PREPARING
                                       │
                                       ├─> Wait (3s) -> status: OUT_FOR_DELIVERY
                                       │
                                       ├─> Emits "location_updated" every 1s
                                       │
                                       └─> After duration -> status: DELIVERED
```

---

## 🌐 API Endpoint Reference

### 🔐 Authentication (`/auth`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/auth/register` | No | Register new user. Returns `{ user, accessToken, refreshToken }` |
| `POST` | `/auth/login` | No | Login user. Returns `{ user, accessToken, refreshToken }` |
| `GET` | `/auth/me` | Bearer | Get logged-in user profile |
| `POST` | `/auth/refresh` | No | Rotate refresh token (revokes old token, issues new pair) |
| `POST` | `/auth/logout` | No | Revoke refresh token |

### 🍕 Restaurants & Menu (`/restaurants`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/restaurants` | No | List restaurants with `search`, `cuisine`, `page`, `limit` |
| `GET` | `/restaurants/:id` | No | Get single restaurant details |
| `GET` | `/restaurants/:id/menu` | No | Get menu items grouped by `category` |

### 📍 Addresses (`/addresses`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `GET` | `/addresses` | Bearer | List user's addresses (default listed first) |
| `POST` | `/addresses` | Bearer | Add new address (manages `is_default` flag) |
| `PUT` | `/addresses/:id` | Bearer | Update user address |
| `DELETE` | `/addresses/:id` | Bearer | Delete user address (re-assigns default if necessary) |

### 📦 Orders (`/orders`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/orders` | Bearer | Create order in 1 DB transaction (computes price from DB) |
| `GET` | `/orders` | Bearer | Get user's order history (paginated, newest first) |
| `GET` | `/orders/:id` | Bearer | Get order details with item snapshots |
| `PATCH` | `/orders/:id/status` | `x-admin-key` | Admin status transition update |
| `POST` | `/orders/:id/cancel` | Bearer | Cancel order (allowed if `PENDING_PAYMENT` or `PLACED`) |

### 💳 Payments (`/payments`)
| Method | Endpoint | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/payments/create` | Bearer | Initialize payment order (Mock or Razorpay) |
| `POST` | `/payments/verify` | Bearer | Verify HMAC signature, set status `PLACED`, start delivery |

---

## ⚡ Socket.IO Events

### Client Events
- `join_order` `{ "orderId": "<uuid>" }`: Subscribes to room `order:<order_id>` (Owner verification enforced).

### Server Events
- `joined_order` `{ "orderId": "<uuid>", "room": "order:<uuid>" }`: Emitted upon successful room join.
- `status_updated` `{ "orderId": "<uuid>", "status": "<NEW_STATUS>" }`: Emitted on order status changes.
- `location_updated` `{ "orderId": "<uuid>", "lat": 12.97, "lng": 77.64 }`: Emitted periodically during `OUT_FOR_DELIVERY`.
