# VitaWallet Exchange — Technical Test

A full-stack crypto exchange mini-app built with **Ruby on Rails API** + **React (TypeScript)**,
designed to demonstrate production-grade engineering patterns.

---

## Architecture Overview

```
exchange-mock-app/
├── backend/     Rails 7 API-only (PostgreSQL + Redis + Sidekiq)
├── frontend/    React 18 + TypeScript + Vite
├── docs/        OpenAPI spec
└── docker-compose.yml
```

### Request flow (Exchange)

```
POST /api/v1/exchanges
  → Rack::Attack (rate limit)
  → authenticate_user!
  → CreateExchangeService
      → validate currency pair
      → validate balance
      → PriceQuoteService  ←→  VitaWallet external API
           ↕ circuit breaker (Stoplight)
           ↕ Redis cache (60s TTL)
      → Exchange.create!(status: pending, locked_rate)
      → ExchangeExecutionJob.perform_later(id)
  → 202 Accepted

[Sidekiq]
  ExchangeExecutionJob
  → ExchangeExecutionService
      → BEGIN TRANSACTION
      → balances.lock! (optimistic locking)
      → validate balance (defense in depth)
      → debit from_currency
      → credit to_currency (BigDecimal arithmetic)
      → exchange.update!(status: completed)
      → COMMIT
```

---

## Architecture Decision Records

### ADR-001: Money — NUMERIC(20,8) + BigDecimal, never Float

All monetary columns use PostgreSQL `NUMERIC(20,8)`. All arithmetic uses `BigDecimal`.

**Why:** Floating-point representation loses precision at scale. At volume,
`0.1 + 0.2 != 0.3` causes real money discrepancies. NUMERIC is exact;
Float is not. This is the #1 cause of financial bugs in production systems.

### ADR-002: Two-Phase Exchange Execution

HTTP request creates the exchange as `pending` (202 Accepted).
Sidekiq job executes it asynchronously.

**Why:** Decouples the HTTP response time from financial execution.
Users get immediate feedback. The job is retryable if it fails.
The locked rate at creation prevents price drift between creation and execution.

### ADR-003: Circuit Breaker on External Price API

Uses `stoplight` gem with Redis state store. After 3 consecutive failures,
the circuit opens and falls back to Redis cache. Returns 503 only if cache is cold.

**Why:** An upstream outage should not make our API unavailable.
The circuit breaker prevents cascading failures and thundering-herd retries.
The Redis fallback gives users stale-but-functional prices during short outages.

### ADR-004: Optimistic Locking on Balances

`balances.lock_version` prevents double-spend under concurrent requests.
`ExchangeExecutionJob` retries on `ActiveRecord::StaleObjectError` via Sidekiq.

**Why:** In a multi-process/multi-threaded environment, two concurrent requests
could each read the same balance, both see sufficient funds, and both debit,
resulting in a negative balance. Optimistic locking detects this conflict.

### ADR-005: Idempotency Keys

`POST /api/v1/exchanges` accepts an `Idempotency-Key` header.
Duplicate keys return the original response without creating a new exchange.

**Why:** Mobile clients on unreliable networks retry requests.
Without idempotency, a retry after a timeout could create duplicate exchanges.
This pattern is standard in financial APIs (Stripe, PayPal, etc).

### ADR-006: DB-Level Constraints as Last Resort

Check constraints at the DB level enforce:
- `balance.amount >= 0` (no negative balances)
- `exchange.status IN ('pending', 'completed', 'rejected')` (no invalid states)
- `exchange.from_amount > 0` (no zero-value exchanges)

**Why:** Application bugs, direct DB writes, or future devs bypassing validations
should not corrupt financial data. The DB is the last line of defense.

### ADR-007: Partial Index on Pending Exchanges

```sql
CREATE INDEX idx_exchanges_pending ON exchanges(user_id, created_at)
WHERE status = 'pending';
```

**Why:** Sidekiq jobs query pending exchanges. Most exchanges complete quickly,
so the pending set is small. A partial index only indexes the rows that matter,
keeping it small and fast as the table grows to millions of rows.

---

## Setup

### Prerequisites
- Docker + Docker Compose
- (Local dev) Ruby 3.0.1, Node 20, PostgreSQL 16, Redis 7

### With Docker (recommended)

```bash
cp .env.example .env  # or set RAILS_MASTER_KEY
docker compose up
docker compose exec backend bundle exec rails db:seed
```

App available at:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3000
- API docs: http://localhost:3000/api-docs (Swagger UI)

### Local Development

```bash
# Backend
cd backend
bundle install
rails db:create db:migrate db:seed
bundle exec rails server

# Sidekiq (separate terminal)
bundle exec sidekiq

# Frontend
cd frontend
npm install
npm run dev
```

### Demo credentials
```
email:    demo@vitawallet.io
password: password123
```

---

## Running Tests

### Backend (RSpec, TDD)

```bash
cd backend
bundle exec rspec --format documentation
```

**93 examples, 0 failures**

Test coverage includes:
- Model specs with DB constraint tests
- Request specs for all API endpoints
- Service specs (CreateExchangeService, ExchangeExecutionService, PriceQuoteService)
- External API mocked with WebMock
- Redis mocked with MockRedis
- Circuit breaker tested with in-memory Stoplight store

### Frontend (Vitest + MSW)

```bash
cd frontend
npm test
npm run type-check
```

**12 tests, 0 failures**

Test coverage includes:
- Custom hooks (useBalances, useCreateExchange) with MSW API mocking
- LoginPage component tests (form behavior, error states)
- HistoryPage component tests (filtering, table rendering)

---

## API Documentation

See `docs/openapi.yml` for the full OpenAPI 3.0 spec.

Key endpoints:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | No | Login |
| GET  | `/api/v1/balances`   | Yes | List balances |
| GET  | `/api/v1/prices`     | Yes | Current crypto prices (cached) |
| POST | `/api/v1/exchanges`  | Yes | Create exchange (202 Accepted) |
| GET  | `/api/v1/exchanges`  | Yes | Exchange history (paginated, filterable) |
| GET  | `/api/v1/exchanges/:id` | Yes | Single exchange |

---

## Technical Decisions & Trade-offs

| Decision | Chosen | Alternative | Reason |
|----------|--------|-------------|--------|
| Auth | Opaque bearer token | JWT | Simpler for this scope; tokens are revocable |
| Background jobs | Sidekiq | ActiveJob inline | Real async execution; retries on failure |
| Cache | Redis | DB cache | Sub-millisecond reads; shared across processes |
| Pagination | Pagy | Kaminari/will_paginate | Fastest Ruby paginator; no monkey-patching |
| Serializers | Blueprinter | AMS/JSONAPI | Explicit, fast, no magic |
| State | React Query | Redux | Server state != UI state; RQ handles caching, loading, refetching |
| Test mocking | WebMock + MockRedis | VCR cassettes | More control, no recorded fixtures to maintain |
| Frontend HTTP mocking | MSW | Axios mock adapter | Tests the actual HTTP layer, not the adapter |
