# Food Delivery — FastAPI Backend

Production-ready FastAPI backend for the Flutter Food Delivery app.

## Architecture

```
Flutter App
    │
    │  Authorization: Bearer <Firebase ID Token>
    ▼
FastAPI
  ├── Firebase Admin SDK  ─── verifies token
  ├── MySQL               ─── users, restaurants, menus, reviews, addresses
  └── MSSQL               ─── orders, payments, transactions
```

**Auth rule:** the backend NEVER implements login/register. Flutter authenticates
with Firebase Auth, then sends the resulting ID token. The backend verifies the
token, derives identity from the `uid` claim, and uses that for every operation.

## Project layout

```
backend/
├── app/
│   ├── main.py                # FastAPI entrypoint
│   ├── init_db.py             # create tables
│   │
│   ├── core/
│   │   ├── config.py          # settings via .env
│   │   ├── firebase.py        # Firebase Admin init + verify
│   │   └── security.py        # get_current_user dependency
│   │
│   ├── db/
│   │   ├── mysql.py           # engine + session
│   │   └── mssql.py           # engine + session
│   │
│   ├── models/
│   │   ├── mysql/             # User, Restaurant, MenuItem, Review, Address
│   │   └── mssql/             # Order, OrderItem, Payment
│   │
│   ├── schemas/               # Pydantic request/response models
│   │   ├── common.py
│   │   ├── auth.py
│   │   ├── mysql.py
│   │   └── mssql.py
│   │
│   ├── services/              # business logic
│   │   ├── user_service.py
│   │   └── order_service.py   # canonical end-to-end order flow
│   │
│   ├── routes/                # API endpoints
│   │   ├── auth.py
│   │   ├── restaurants.py
│   │   ├── menu.py
│   │   ├── addresses.py
│   │   ├── reviews.py
│   │   ├── orders.py
│   │   └── payments.py
│   │
│   └── utils/
│       └── helpers.py
│
├── requirements.txt
├── .env                       # local config (do not commit)
└── firebase.json              # Firebase service-account credentials
```

## Setup

### 1. Create and activate a virtual environment

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure `.env`

Edit `backend/.env` with your database credentials and Firebase project ID.

### 4. Add Firebase credentials

Place a service-account JSON file at `backend/firebase.json`. The file referenced
in the project root can be used directly if it has the right shape.

### 5. Create database tables

```bash
python -m app.init_db
```

This creates all MySQL and MSSQL tables.

### 6. Run the server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Interactive docs: <http://localhost:8000/docs>

## Authentication

All non-public endpoints require:

```
Authorization: Bearer <Firebase ID Token>
```

Send the token your Flutter app received from
`FirebaseAuth.instance.currentUser?.getIdToken()`. The backend decodes it,
extracts the `uid`, and never trusts any client-supplied user id.

## End-to-end order flow

1. Flutter user logs in via Firebase Auth.
2. Flutter calls `POST /api/v1/auth/sync-user` to create the local user record.
3. Flutter calls `POST /api/v1/orders` with `{restaurant_id, items, delivery_address, payment_method}`.
4. Backend:
   1. Verifies Firebase token → gets `uid`.
   2. Looks up menu items and prices from MySQL.
   3. Creates an `Order` + initial `Payment` in MSSQL atomically.
   4. Returns the full order with items.
5. Flutter calls `PATCH /api/v1/payments/{id}` to mark the payment as `paid` after the gateway confirms.

## Useful endpoints

| Method | Path                                  | Auth | Purpose                          |
|--------|---------------------------------------|------|----------------------------------|
| GET    | `/health`                             | no   | Liveness + DB reachability       |
| GET    | `/api/v1/auth/me`                     | yes  | Current Firebase + DB user       |
| POST   | `/api/v1/auth/sync-user`              | yes  | Create/update local user         |
| GET    | `/api/v1/restaurants`                 | no   | List restaurants                 |
| POST   | `/api/v1/restaurants`                 | yes  | Create restaurant (owner)        |
| GET    | `/api/v1/menu/restaurant/{id}`        | no   | List menu items                  |
| POST   | `/api/v1/orders`                      | yes  | Create order (end-to-end)        |
| GET    | `/api/v1/orders/me`                   | yes  | My order history                 |
| PATCH  | `/api/v1/orders/{id}/status`          | yes  | Update order status              |
| GET    | `/api/v1/payments/me`                 | yes  | My payment history               |
| PATCH  | `/api/v1/payments/{id}`               | yes  | Update payment status            |

## Security notes

- `user_id` is NEVER accepted from the client. All identity comes from the
  verified Firebase token.
- CORS is wide-open in development — restrict `allow_origins` for production.
- `firebase.json` contains a private key — keep it out of version control.
- Database connection pooling is configured with `pool_pre_ping` and
  `pool_recycle` to handle dropped connections gracefully.
