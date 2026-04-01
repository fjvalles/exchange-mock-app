# VitaWallet Exchange — Prueba Técnica

Una mini-aplicación de intercambio de criptomonedas full-stack construida con **Ruby on Rails API** + **React (TypeScript)**, diseñada para demostrar patrones de ingeniería de nivel de producción.

---

### 🚀 **Demo en Vivo:** [frontend-7lto.onrender.com](https://frontend-7lto.onrender.com/)

**Credenciales de acceso:**
- **Email:** `demo@vitawallet.io`
- **Password:** `password123`

---

## Resumen de la Arquitectura

```
exchange-mock-app/
├── backend/     Rails 7 API-only (PostgreSQL + Redis + Sidekiq)
├── frontend/    React 18 + TypeScript + Vite
├── docs/        Especificación OpenAPI
└── docker-compose.yml
```

## 🏗️ Arquitectura del Sistema

```mermaid
graph LR
    User((Usuario)) --> FE[Frontend React]
    FE --> API[API Rails]
    
    subgraph "Lógica y Datos"
        API --> DB[(PostgreSQL)]
        API --> Redis{Redis}
        Redis --> Sidekiq[Sidekiq Worker]
        Sidekiq --> DB
    end

    subgraph "Integración Precios"
        API -.-> CB[Circuit Breaker]
        CB -.-> VW_API([API VitaWallet])
    end
```

### 🔁 Flujo del Intercambio
1. **Cliente**: El usuario solicita un intercambio (POST).
2. **API**: Valida el saldo y encola la ejecución en **Sidekiq**.
3. **Worker**: Sidekiq procesa el cambio de divisas de forma atómica en la **Base de Datos**.

---

## 💎 Decisiones Técnicas y Razonamiento

Hemos construido esta aplicación priorizando la **seguridad financiera** y la **robustez**. Aquí el porqué de nuestras decisiones clave bajo los requisitos del desafío:

> [!IMPORTANT]
> ### 1. Precisión Financiera: NUMERIC(20,8) + BigDecimal
> **Decisión:** Nunca usamos el tipo `Float`. Todas las columnas monetarias son `NUMERIC(20,8)` y los cálculos se hacen con `BigDecimal`.
> **Por qué:** En finanzas, `0.1 + 0.2` debe ser exactamente `0.3`. Los números de punto flotante (`Float`) causan micro-pérdidas por redondeo binario que, a escala, se traducen en discrepancias graves de dinero real.

> [!TIP]
> ### 2. Experiencia de Usuario: Ejecución Asíncrona (Sidekiq)
> **Decisión:** El intercambio se acepta de inmediato (`202 Accepted`) y se procesa en segundo plano.
> **Por qué:** No hacemos esperar al usuario a que la base de datos complete transacciones pesadas. La respuesta es instantánea. Al "bloquear" la tasa al momento de la creación, protegemos al usuario de la volatilidad del precio durante esos milisegundos de espera.

> [!CAUTION]
> ### 3. Red de Seguridad: Idempotencia y Circuit Breaker
> **Decisión:** Implementamos `Idempotency-Key` en los POST y un corta-fuegos (`Stoplight`) en la API de precios.
> **Por qué:** Si el móvil del usuario pierde conexión justo tras darle a "Intercambiar", el reintento no creará un segundo intercambio por error. Si la API de VitaWallet cae, el Circuit Breaker sirve precios en caché en milisegundos, manteniendo la app operativa.

> [!NOTE]
> ### 4. Integridad de Datos: Bloqueo Optimista
> **Decisión:** Uso de `lock_version` en los balances.
> **Por qué:** Evita el famoso "doble gasto". Si dos procesos intentan debitar de la misma cuenta al mismo tiempo, el bloqueo optimista detecta el conflicto y Sidekiq reintenta la operación de forma segura.

> [!IMPORTANT]
> ### 5. Autenticación: Tokens Opacos vs JWT
> **Decisión:** Uso de `api_token` (almacenado en BD) en lugar de tokens JWT.
> **Por qué:** En apps financieras, la **revocación inmediata** es ley. Con un `api_token`, si detectamos actividad sospechosa, invalidamos la fila en la BD y el acceso se corta al instante. Con JWT, tendríamos que esperar a que el token expire o implementar una lista negra compleja.

> [!TIP]
> ### 6. Agilidad en el Frontend: Vite + TypeScript
> **Decisión:** Migración de Create React App (CRA) a **Vite**.
> **Por qué:** Vite usa ES Modules nativos, lo que significa que el servidor de desarrollo arranca en milisegundos y el HMR (refresco de cambios) es instantáneo. En una prueba técnica, esta velocidad se traduce en una mayor calidad de código y un feedback loop mucho más corto.

> [!CAUTION]
> ### 7. Escalabilidad: Arquitectura Multi-Contenedor (Docker)
> **Decisión:** Separación estricta de la API (Rails), el motor de Jobs (Sidekiq), la BD (Postgres) y el Caché (Redis) en servicios Docker independientes.
> **Por qué:** Permite el **escalado horizontal independiente**. Si el volumen de intercambios crece, podemos escalar solo los trabajadores de Sidekiq sin consumir recursos extra en el servidor de la API, manteniendo los costes bajos y el rendimiento alto.

---

## 🛠️ Configuración y Despliegue

### Requisitos Previos
- Docker + Docker Compose instalado.

### Instalación Rápida (Recomendado)

1. **Clonar e Iniciar:**
   ```bash
   cp .env.example .env
   docker compose up
   ```
2. **Preparar la Base de Datos:**
   ```bash
   docker compose exec backend bin/rails db:seed
   ```

| Servicio | URL |
| :--- | :--- |
| **Frontend** | http://localhost:5173 |
| **API Backend** | http://localhost:3000 |
| **Swagger Docs** | http://localhost:3000/api-docs |

---

## 🧪 Estrategia de Pruebas

Hemos blindado el sistema con **111 tests automatizados** para garantizar que cada moneda se mueva siempre al lugar correcto.

- **Backend (92 RSpec)**: Probamos desde las restricciones de integridad en la DB hasta la lógica de "cross-rate" para intercambios entre cualquier moneda (BTC/USDT, USD/BTC, etc).
- **Frontend (19 Vitest)**: Simulamos el flujo completo del usuario, incluyendo validación de saldos en tiempo real y estados de carga.

---

## 🚀 Qué quedó pendiente

Aunque el sistema es funcional y robusto, para una versión de producción se podrían implementar las siguientes mejoras:

**Seguridad y autenticación:**

1.  **Invalidación de token en logout:** El endpoint `POST /auth/logout` actualmente retorna éxito sin invalidar el token en base de datos. En producción, se debería regenerar o eliminar el `api_token` del usuario para que un token robado no pueda usarse después de cerrar sesión — especialmente crítico en una app financiera.
2.  **Almacenamiento seguro del token (httpOnly cookies):** El token de autenticación se persiste en `localStorage`, que es accesible desde JavaScript. Esto lo expone a ataques XSS. La solución es moverlo a una cookie `httpOnly; Secure; SameSite=Strict`, que el navegador no permite leer desde JS bajo ninguna circunstancia.
3.  **IDs secuenciales en exchanges:** El endpoint `GET /exchanges/:id` filtra correctamente por `current_user`, por lo que un usuario no puede acceder a exchanges ajenos. Sin embargo, los IDs siendo secuenciales permite inferir el volumen total de operaciones del sistema. Se podría mitigar usando UUIDs como identificador público.

**Lógica de negocio:**

4.  **Tasa USD/CLP hardcodeada:** La API de VitaWallet solo devuelve precios para BTC, USDC y USDT contra CLP — no incluye USD. Para calcular cross-rates con USD se usa una tasa fija (`920/940 CLP`). En producción esto debería consumirse de una API en tiempo real (Fixer.io, ExchangeRate-API, Banco Central de Chile) para evitar arbitraje sistemático cuando la tasa real difiere significativamente.
5.  **Validación de monto mínimo:** No existe un mínimo validado para `from_amount`. Un usuario puede enviar valores extremadamente pequeños (ej: `0.00000001`) y se generará un exchange válido. En producción se debería establecer un monto mínimo por par de monedas.
6.  **Race condition entre validación y ejecución:** El chequeo de saldo suficiente ocurre dos veces: al crear el exchange (sin lock) y al ejecutarlo (con lock). Si un usuario dispara dos requests simultáneos muy rápido, ambos pueden pasar la primera validación antes de que alguno ejecute. El segundo fallará con `rejected` — no se pierde dinero — pero se generan dos registros `pending` momentáneamente. Se podría eliminar con un lock optimista ya en la fase de creación.

**Escalabilidad y concurrencia:**

7.  **Puma en modo cluster:** Actualmente Puma corre con un solo proceso y 5 threads (`workers` está comentado en `config/puma.rb`), lo que limita la concurrencia real a ~5 requests simultáneos. Para producción se debe activar el modo cluster (`workers WEB_CONCURRENCY`) con `preload_app!` para aprovechar Copy-on-Write y escalar horizontalmente.
8.  **Pool de conexiones a PostgreSQL:** El pool está fijado en 5 conexiones (igual que `RAILS_MAX_THREADS`). Al escalar Puma a más workers/threads, cada proceso necesita su propio pool — si no se ajusta `pool` y `RAILS_MAX_THREADS` acorde, aparecen errores `ConnectionTimeoutError` bajo carga. Se recomienda configurar ambos explícitamente y considerar PgBouncer como proxy de conexiones.
9.  **Concurrencia en Sidekiq:** El worker arranca con la configuración por defecto (10 threads). Para carga alta se debería configurar explícitamente la concurrencia en `sidekiq.yml` y ajustar el pool de DB del worker de forma independiente al de la API.

**Producción multi-país:**

10. **HTTPS forzado y HSTS:** No hay configuración que fuerce HTTPS ni cabeceras `Strict-Transport-Security`. En producción todo el tráfico debe ir cifrado y el navegador debe rechazar conexiones HTTP directamente.
11. **Expiración de tokens:** Los `api_token` no tienen TTL — una vez creados son válidos para siempre. En producción deberían expirar (ej: 24h de inactividad) y requerir re-autenticación, reduciendo la ventana de exposición si un token es comprometido.
12. **Audit trail de operaciones:** No existe un log de quién hizo qué y desde dónde. En finanzas reguladas es obligatorio registrar cada acción sensible (login, exchange, cambio de datos) con timestamp, IP y user-agent para fines de auditoría y detección de fraude.
13. **KYC/AML básico:** Con clientes reales de múltiples países, la regulación financiera exige verificar la identidad del usuario (Know Your Customer) y detectar patrones de operaciones sospechosas (Anti-Money Laundering). Actualmente cualquier cuenta puede operar sin ningún tipo de verificación.
14. **Zonas horarias por usuario:** Todas las fechas se almacenan en UTC correctamente, pero el frontend las muestra sin conversión a la zona horaria local del usuario. Un cliente en Asia ve los `executed_at` en UTC sin contexto.
15. **Notificaciones al usuario:** No hay ningún mecanismo para avisar al usuario cuando un exchange se completa o es rechazado. El procesamiento es asíncrono, por lo que el usuario debe volver a la app para enterarse del resultado — en producción se esperaría al menos un email o push notification.
16. **Reconciliación de exchanges stuck:** Si el proceso de Sidekiq muere con jobs en vuelo, los exchanges quedan en `pending` indefinidamente sin ningún mecanismo que los detecte y resuelva. Se necesita un job de reconciliación periódico que marque como `rejected` los exchanges que lleven más de N minutos en `pending`.

**Observabilidad y calidad:**

17. **Actualizaciones en Tiempo Real (WebSockets):** Implementar **ActionCable** para que los precios y los saldos se actualicen instantáneamente en el Dashboard sin necesidad de recargar o hacer polling manual.
18. **Pruebas de Extremo a Extremo (E2E):** Añadir una suite de **Playwright** o **Cypress** para validar el flujo crítico de "Login -> Intercambio -> Historial" en navegadores reales.
19. **Gráficos de Historial de Precios:** Integrar una librería de visualización (como Recharts o Lightweight Charts) para mostrar la evolución de la tasa de cambio en las últimas 24 horas.
20. **Internacionalización (i18n):** Soporte multi-idioma (Español/Inglés) tanto en el backend como en el frontend para usuarios globales.
21. **Observabilidad Avanzada:** Integrar **Sentry** para el rastreo de errores en tiempo real y **Prometheus/Grafana** para monitorear el rendimiento de Sidekiq y los tiempos de respuesta de la API.

---

## 🌐 Documentación de la API

La especificación completa **OpenAPI 3.0** está disponible en `docs/openapi.yml`. El sistema soporta intercambios dinámicos entre **CLP, USD, BTC, USDC y USDT** de forma automática.
