# VitaWallet — Backend API

This is the Ruby on Rails 7 API for the VitaWallet mock exchange.

## Tech Stack
- **Ruby 3.1.2**
- **Rails 7.1**
- **PostgreSQL 16** (Primary DB with numeric precision)
- **Redis 7** (Cache & Sidekiq store)
- **Sidekiq** (Async exchange execution)

## Key Features
- **Arbitrary Currency Exchange**: Automatic cross-rate logic via CLP for any pair (CLP, USD, BTC, USDC, USDT).
- **Idempotent API**: Supports `Idempotency-Key` headers for financial safety.
- **Circuit Breaker**: Robust integration with external price APIs via `Stoplight`.
- **Financial Precision**: Using `BigDecimal` everywhere.

## Development & Testing
Refer to the [Root README](../README.md) for full setup and test instructions using Docker.

To run only backend tests locally:
```bash
bundle exec rspec
```

## API Documentation
The OpenAPI 3.0 spec is located at `public/openapi.yml`.
When running locally, visit `http://localhost:3000/api-docs`.
