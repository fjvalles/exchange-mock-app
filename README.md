# VitaWallet Exchange — Prueba Técnica

Una mini-aplicación de intercambio de criptomonedas full-stack construida con **Ruby on Rails API** + **React (TypeScript)**, diseñada para demostrar patrones de ingeniería de nivel de producción.

---

## Resumen de la Arquitectura

```
exchange-mock-app/
├── backend/     Rails 7 API-only (PostgreSQL + Redis + Sidekiq)
├── frontend/    React 18 + TypeScript + Vite
├── docs/        Especificación OpenAPI
└── docker-compose.yml
```

### Flujo de Solicitud (Intercambio)

```
POST /api/v1/exchanges
  → Rack::Attack (límite de peticiones)
  → authenticate_user!
  → CreateExchangeService
      → validar par de divisas (cualquier combinación)
      → validar saldo del usuario
      → PriceQuoteService  ←→  API externa de VitaWallet
           ↕ circuit breaker (Stoplight)
           ↕ Caché en Redis (60s TTL)
      → Exchange.create!(status: pending, locked_rate)
      → ExchangeExecutionJob.perform_later(id)
  → 202 Accepted

[Sidekiq]
  ExchangeExecutionJob
  → ExchangeExecutionService
      → BEGIN TRANSACTION
      → balances.lock! (bloqueo optimista)
      → validar saldo (defensa en profundidad)
      → débito moneda_origen
      → crédito moneda_destino (aritmética BigDecimal)
      → exchange.update!(status: completed)
      → COMMIT
```

---

## Registros de Decisiones de Arquitectura (ADR)

### ADR-001: Dinero — NUMERIC(20,8) + BigDecimal, nunca Float

Todas las columnas monetarias usan PostgreSQL `NUMERIC(20,8)`. Toda la aritmética usa `BigDecimal`.

**Por qué:** La representación de punto flotante pierde precisión a escala. En volumen, `0.1 + 0.2 != 0.3` causa discrepancias reales de dinero. NUMERIC es exacto; Float no. Esta es la causa #1 de errores financieros en sistemas de producción.

### ADR-002: Ejecución de Intercambio en Dos Fases

La solicitud HTTP crea el intercambio como `pending` (202 Accepted). El job de Sidekiq lo ejecuta de forma asíncrona.

**Por qué:** Desacopla el tiempo de respuesta HTTP de la ejecución financiera. Los usuarios reciben feedback inmediato. El job es reintentable si falla. La tasa bloqueada (`locked_rate`) en la creación evita desplazamientos de precios entre la solicitud y la ejecución.

### ADR-003: Circuit Breaker en API Externa de Precios

Se usa la gema `stoplight` con almacenamiento de estado en Redis. Después de 3 fallos consecutivos, el circuito se abre y recurre al caché de Redis. Devuelve 503 solo si el caché está vacío.

**Por qué:** Una caída de un proveedor externo no debe tirar nuestra API. El circuit breaker evita fallos en cascada y reintentos masivos. El fallback de Redis ofrece a los usuarios precios "vencidos" pero funcionales durante cortes cortos.

### ADR-004: Bloqueo Optimista en Saldos

`balances.lock_version` evita el doble gasto bajo solicitudes concurrentes. `ExchangeExecutionJob` reintenta ante `ActiveRecord::StaleObjectError` mediante Sidekiq.

**Por qué:** En un entorno multiproceso/multihilo, dos solicitudes concurrentes podrían leer el mismo saldo, ver fondos suficientes y debitar ambas, resultando en un saldo negativo. El bloqueo optimista detecta este conflicto.

### ADR-005: Claves de Idempotencia

`POST /api/v1/exchanges` acepta un encabezado `Idempotency-Key`. Las claves duplicadas devuelven la respuesta original sin crear un nuevo intercambio.

**Por qué:** Los clientes móviles en redes inestables suelen reintentar peticiones. Sin idempotencia, un reintento tras un timeout podría crear intercambios duplicados. Este patrón es estándar en APIs financieras (Stripe, PayPal, etc).

---

## Configuración

### Requisitos Previos
- Docker + Docker Compose
- (Desarrollo local) Ruby 3.0.1, Node 20, PostgreSQL 16, Redis 7

### Con Docker (recomendado)

```bash
cp .env.example .env  # o configurar RAILS_MASTER_KEY
docker compose up
docker compose exec backend bin/rails db:seed
```

La aplicación estará disponible en:
- Frontend: http://localhost:5173
- API Backend: http://localhost:3000
- Documentación API: http://localhost:3000/api-docs (Swagger UI)

### Credenciales de Demo
```
email:    demo@vitawallet.io
password: password123
```

---

## Ejecución de Tests

### Backend (RSpec, TDD)

```bash
cd backend
bundle exec rspec --format documentation
```

**92 ejemplos, 0 fallos**

La cobertura de tests incluye:
- Specs de modelos con pruebas de restricciones de BD
- Specs de peticiones para todos los endpoints de la API
- Specs de servicios (soporte de pares arbitrarios con lógica de tasas cruzadas)
- API externa mockeada con WebMock
- Redis mockeado con MockRedis

### Frontend (Vitest + MSW)

```bash
cd frontend
npm test
```

**19 tests, 0 fallos**

La cobertura de tests incluye:
- Hooks personalizados (useBalances, useCreateExchange) con mockeo de API MSW
- Tests de componentes (LoginPage, DashboardPage, ExchangePage, HistoryPage)
- Validaciones de flujo completo de intercambio y formateo de monedas

---

## Documentación de la API

Consulta `docs/openapi.yml` para la especificación completa OpenAPI 3.0.

Endpoints clave:

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | No | Iniciar sesión |
| GET  | `/api/v1/balances`   | Sí | Listar saldos |
| GET  | `/api/v1/prices`     | Sí | Precios actuales (con caché) |
| POST | `/api/v1/exchanges`  | Sí | Crear intercambio (202 Accepted) |
| GET  | `/api/v1/exchanges`  | Sí | Historial (paginado, filtrable) |
| GET  | `/api/v1/exchanges/:id` | Sí | Detalle de intercambio |
