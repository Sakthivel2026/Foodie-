# Foodie API Contract & Socket Documentation

This document serves as the authoritative API and Realtime Contract reference for `foodie_app`, derived directly from `foodie_backend`.

---

## 1. Base Configuration & Global Standards

- **Base URL**: `http://10.0.2.2:3000` (Android Emulator default) or via `--dart-define=API_BASE_URL=<url>`
- **Monetary Values**: All money amounts are strictly integers in **paise** (`1 INR = 100 paise`). Double floating point numbers are never used for currency.
- **Authentication**: JWT Bearer token authentication via `Authorization: Bearer <accessToken>` header on protected endpoints.
- **Error Response Format**: Standard error responses return JSON with an `error` key:
  ```json
  { "error": "Description of error" }
  ```
- **Pagination Format**: Standard paginated endpoints return:
  ```json
  {
    "data": [ ... ],
    "page": 1,
    "limit": 10,
    "total": 42,
    "totalPages": 5
  }
  ```

---

## 2. Authentication Endpoints (`/auth`)

### `POST /auth/register`
- **Auth**: None
- **Request Body**:
  ```json
  {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "password": "password123"
  }
  ```
- **Validation**: `name` (min 2 chars), `email` (valid email format), `password` (min 6 chars on backend schema).
- **Success (201 Created)**:
  ```json
  {
    "user": {
      "id": "uuid",
      "name": "Jane Doe",
      "email": "jane@example.com",
      "created_at": "ISO-8601 string"
    },
    "accessToken": "jwt_string",
    "refreshToken": "hex_string"
  }
  ```
- **Errors**:
  - `400 Bad Request`: Validation failure.
  - `409 Conflict`: `{ "error": "Email already registered" }`
  - `429 Too Many Requests`: Rate limiter triggered.

### `POST /auth/login`
- **Auth**: None
- **Request Body**:
  ```json
  {
    "email": "jane@example.com",
    "password": "password123"
  }
  ```
- **Success (200 OK)**: Same response shape as `/auth/register`.
- **Errors**:
  - `401 Unauthorized`: `{ "error": "Invalid email or password" }`
  - `429 Too Many Requests`: Rate limiter triggered.

### `GET /auth/me`
- **Auth**: Bearer Token
- **Success (200 OK)**:
  ```json
  {
    "user": {
      "id": "uuid",
      "name": "Jane Doe",
      "email": "jane@example.com",
      "created_at": "ISO-8601 string"
    }
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Invalid / expired access token.
  - `404 Not Found`: `{ "error": "User not found" }`

### `POST /auth/refresh`
- **Auth**: None
- **Request Body**:
  ```json
  {
    "refreshToken": "hex_string"
  }
  ```
- **Success (200 OK)**: Rotates refresh token and returns new pair:
  ```json
  {
    "user": { ... },
    "accessToken": "new_jwt_string",
    "refreshToken": "new_hex_string"
  }
  ```
- **Errors**:
  - `401 Unauthorized`: `{ "error": "Invalid or expired refresh token" }` or `{ "error": "Refresh token has been revoked" }`

### `POST /auth/logout`
- **Auth**: None
- **Request Body**:
  ```json
  {
    "refreshToken": "hex_string"
  }
  ```
- **Success (200 OK)**: `{ "message": "Logged out successfully" }`

---

## 3. Restaurants & Menu Endpoints (`/restaurants`)

### `GET /restaurants`
- **Auth**: None
- **Query Params**:
  - `search` (optional string): Filter by restaurant name (case-insensitive substring)
  - `cuisine` (optional string): Filter by cuisine type
  - `page` (optional int, default 1)
  - `limit` (optional int, default 10, max 50)
- **Success (200 OK)**:
  ```json
  {
    "data": [
      {
        "id": "uuid",
        "name": "Tandoori Nights",
        "cuisine": "North Indian",
        "image_url": "https://...",
        "rating": "4.5",
        "delivery_time_min": 30,
        "delivery_fee_paise": 4900,
        "lat": "12.9715987",
        "lng": "77.5945627",
        "is_open": true,
        "created_at": "ISO-8601 string"
      }
    ],
    "page": 1,
    "limit": 10,
    "total": 12,
    "totalPages": 2
  }
  ```

### `GET /restaurants/:id`
- **Auth**: None
- **Success (200 OK)**: Single restaurant object (same shape as array elements above).
- **Errors**:
  - `404 Not Found`: `{ "error": "Restaurant not found" }`

### `GET /restaurants/:id/menu`
- **Auth**: None
- **Query Params**: `category` (optional string)
- **Success (200 OK)**:
  ```json
  {
    "categories": {
      "Starters": [
        {
          "id": "uuid",
          "restaurant_id": "uuid",
          "name": "Paneer Tikka",
          "description": "Spiced grilled cottage cheese",
          "price_paise": 25000,
          "image_url": "https://...",
          "is_veg": true,
          "category": "Starters",
          "is_available": true,
          "created_at": "ISO-8601 string"
        }
      ]
    },
    "items": [ ... ]
  }
  ```
- **Errors**:
  - `404 Not Found`: `{ "error": "Restaurant not found" }`

---

## 4. Address Endpoints (`/addresses`)

### `GET /addresses`
- **Auth**: Bearer Token
- **Success (200 OK)**: Array of addresses ordered by `is_default DESC, created_at DESC`:
  ```json
  [
    {
      "id": "uuid",
      "user_id": "uuid",
      "label": "Home",
      "line1": "123 Koramangala 4th Block",
      "line2": "Apt 4B",
      "city": "Bangalore",
      "pincode": "560034",
      "lat": "12.9345321",
      "lng": "77.6242109",
      "is_default": true,
      "created_at": "ISO-8601 string"
    }
  ]
  ```

### `POST /addresses`
- **Auth**: Bearer Token
- **Request Body**:
  ```json
  {
    "label": "Home",
    "line1": "123 Koramangala 4th Block",
    "line2": "Apt 4B",
    "city": "Bangalore",
    "pincode": "560034",
    "lat": 12.9345,
    "lng": 77.6242,
    "is_default": true
  }
  ```
- **Success (201 Created)**: Created address object.
- **Rules**: First address created automatically becomes default. If `is_default` is true, previous default address is unset.

### `PUT /addresses/:id`
- **Auth**: Bearer Token
- **Request Body**: Partial address object fields.
- **Success (200 OK)**: Updated address object.
- **Errors**:
  - `404 Not Found`: `{ "error": "Address not found" }`

### `DELETE /addresses/:id`
- **Auth**: Bearer Token
- **Success (200 OK)**: `{ "message": "Address deleted successfully" }`
- **Rules**: If default address is deleted, the most recently created remaining address is promoted to default.
- **Errors**:
  - `404 Not Found`: `{ "error": "Address not found" }`

---

## 5. Order Endpoints (`/orders`)

### `POST /orders`
- **Auth**: Bearer Token
- **Request Body**:
  ```json
  {
    "restaurantId": "uuid",
    "addressId": "uuid",
    "items": [
      {
        "menuItemId": "uuid",
        "quantity": 2
      }
    ]
  }
  ```
- **Tax Calculation**: `tax_paise = Math.round(subtotal_paise * 0.05)` (5% tax).
- **Total Calculation**: `total_paise = subtotal_paise + delivery_fee_paise + tax_paise`.
- **Success (201 Created)**:
  ```json
  {
    "id": "uuid",
    "user_id": "uuid",
    "restaurant_id": "uuid",
    "address_id": "uuid",
    "status": "PENDING_PAYMENT",
    "payment_status": "PENDING",
    "subtotal_paise": 50000,
    "delivery_fee_paise": 4900,
    "tax_paise": 2500,
    "total_paise": 57400,
    "created_at": "ISO-8601 string",
    "updated_at": "ISO-8601 string",
    "items": [
      {
        "id": "uuid",
        "order_id": "uuid",
        "menu_item_id": "uuid",
        "name_snapshot": "Paneer Tikka",
        "price_paise_snapshot": 25000,
        "quantity": 2
      }
    ]
  }
  ```
- **Errors**:
  - `400 Bad Request`: `{ "error": "Restaurant is currently closed" }` or `{ "error": "One or more menu items are unavailable or do not belong to this restaurant" }`
  - `404 Not Found`: `{ "error": "Address not found" }` or `{ "error": "Restaurant not found" }`

### `GET /orders`
- **Auth**: Bearer Token
- **Query Params**: `page` (default 1), `limit` (default 10)
- **Success (200 OK)**:
  ```json
  {
    "data": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "restaurant_id": "uuid",
        "address_id": "uuid",
        "status": "PLACED",
        "payment_status": "PAID",
        "subtotal_paise": 50000,
        "delivery_fee_paise": 4900,
        "tax_paise": 2500,
        "total_paise": 57400,
        "restaurant_name": "Tandoori Nights",
        "restaurant_image_url": "https://...",
        "created_at": "ISO-8601 string",
        "updated_at": "ISO-8601 string",
        "items": [ ... ]
      }
    ],
    "page": 1,
    "limit": 10,
    "total": 1,
    "totalPages": 1
  }
  ```

### `GET /orders/:id`
- **Auth**: Bearer Token
- **Success (200 OK)**: Single order object with `restaurant_name`, `restaurant_image_url`, and `items`.
- **Errors**:
  - `404 Not Found`: `{ "error": "Order not found" }`

### `PATCH /orders/:id/status` (Admin Transition)
- **Auth**: Header `x-admin-key: super_secret_admin_key_123`
- **Request Body**: `{ "status": "PLACED" }`
- **Allowed Transitions**:
  - `PENDING_PAYMENT` -> `PLACED`, `CANCELLED`
  - `PLACED` -> `PREPARING`, `CANCELLED`
  - `PREPARING` -> `OUT_FOR_DELIVERY`, `CANCELLED`
  - `OUT_FOR_DELIVERY` -> `DELIVERED`
- **Errors**:
  - `403 Forbidden`: Invalid admin key.
  - `400 Bad Request`: Invalid transition.

### `POST /orders/:id/cancel`
- **Auth**: Bearer Token
- **Success (200 OK)**: Updated order with `status: "CANCELLED"`.
- **Rules**: Allowed ONLY when status is `PENDING_PAYMENT` or `PLACED`.
- **Errors**:
  - `400 Bad Request`: `{ "error": "Order cannot be cancelled at this stage" }`
  - `404 Not Found`: `{ "error": "Order not found" }`

---

## 6. Payment Endpoints (`/payments`)

### `POST /payments/create`
- **Auth**: Bearer Token
- **Request Body**: `{ "orderId": "uuid" }`
- **Success (200 OK)**:
  ```json
  {
    "razorpayOrderId": "order_mock_1234567890abcdef",
    "amountPaise": 57400,
    "currency": "INR",
    "keyId": "mock_key_id",
    "mode": "mock"
  }
  ```
- **Errors**:
  - `400 Bad Request`: `{ "error": "Order is not pending payment" }`
  - `404 Not Found`: `{ "error": "Order not found" }`

### `POST /payments/verify`
- **Auth**: Bearer Token
- **Request Body**:
  ```json
  {
    "orderId": "uuid",
    "razorpay_order_id": "order_mock_1234567890abcdef",
    "razorpay_payment_id": "pay_mock_123456",
    "razorpay_signature": "mock_signature"
  }
  ```
- **Mock Mode Verification Rules**:
  - Signature is valid IF `razorpay_signature === "mock_signature"`
  - OR IF `razorpay_signature` matches HMAC-SHA256 of `${razorpay_order_id}|${razorpay_payment_id}` using `RAZORPAY_KEY_SECRET` (default `'mock_secret'`).
- **Success (200 OK)**:
  ```json
  {
    "message": "Payment verified successfully",
    "order": { ... }
  }
  ```
  *(Updates order status to `PLACED`, `payment_status` to `PAID`, and triggers the asynchronous delivery simulator)*
- **Idempotency**: If order is already `PAID`, returns `{ "message": "Payment already verified", "order": { ... } }`.
- **Errors**:
  - `400 Bad Request`: `{ "error": "Invalid payment signature" }` (Updates payment status to `FAILED`).

---

## 7. Socket.IO Realtime Tracking Contract

- **Handshake Connection**:
  - Connect to base URL (e.g. `http://10.0.2.2:3000`).
  - Auth payload: `auth: { token: "<access_token>" }` or `extraHeaders: { Authorization: "Bearer <access_token>" }`.
- **Subscribing to Order Room**:
  - Client emits `join_order` with payload `{ "orderId": "<uuid>" }` (or string `"<uuid>"`).
  - Server validates user ownership of the order.
- **Server Events**:
  - `joined_order`: `{ "orderId": "<uuid>", "room": "order:<uuid>" }`
  - `status_updated`: `{ "orderId": "<uuid>", "status": "PREPARING" | "OUT_FOR_DELIVERY" | "DELIVERED" }`
  - `location_updated`: `{ "orderId": "<uuid>", "lat": 12.9715987, "lng": 77.5945627 }` (Emitted every 1 second when order is `OUT_FOR_DELIVERY`).
  - `error`: `{ "error": "Unauthorized to join room for this order" }`

---

## 8. Backend Audit & Inconsistency Findings

1. **Password Length Validation Mismatch**:
   - Backend Zod schema in `auth.controller.js` (`registerSchema`) enforces a minimum password length of **6 characters**.
   - Frontend validation rules specify a minimum password length of **8 characters**.
2. **Address Default Flag Edge Case**:
   - When updating an address with `is_default: false` when it was previously `is_default: true`, the backend sets `is_default = false` without promoting another address, leaving the user with zero default addresses.
3. **Response Key Naming (Snake_case vs CamelCase)**:
   - Order & Payment fields in DB responses use snake_case (`subtotal_paise`, `total_paise`, `razorpay_order_id`, `razorpay_payment_id`), but `/payments/create` returns mixed camelCase keys (`razorpayOrderId`, `amountPaise`). Models in `foodie_app` must handle these exact key names.
