# VitaWallet — API Backend

Este es el backend de Ruby on Rails 7 para el simulador de intercambio de VitaWallet.

## Stack Tecnológico
- **Ruby 3.1.2**
- **Rails 7.1**
- **PostgreSQL 16** (Base de datos principal con precisión numérica)
- **Redis 7** (Cache y almacenamiento de Sidekiq)
- **Sidekiq** (Ejecución de intercambios asíncronos)

## Características Clave
- **Intercambio de Monedas Arbitrario**: Lógica automática de tasas cruzadas vía CLP para cualquier par (CLP, USD, BTC, USDC, USDT).
- **API Idempotente**: Soporte de encabezados `Idempotency-Key` para seguridad financiera.
- **Circuit Breaker**: Integración robusta con APIs externas de precios mediante `Stoplight`.
- **Precisión Financiera**: Uso de `BigDecimal` en todos los cálculos monetarios.

## Desarrollo y Pruebas
Consulta el [README raíz](../README.md) para instrucciones completas de configuración y ejecución con Docker.

Para correr solo los tests del backend localmente:
```bash
bundle exec rspec
```

## Documentación de la API
La especificación OpenAPI 3.0 se encuentra en `public/openapi.yml`.
Cuando corras localmente, visita `http://localhost:3000/api-docs`.
