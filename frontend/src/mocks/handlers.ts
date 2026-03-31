import { http, HttpResponse } from 'msw'

const BASE = 'http://localhost:3000/api/v1'

export const handlers = [
  http.post(`${BASE}/auth/login`, async ({ request }) => {
    const body = await request.json() as { email: string; password: string }
    if (body.email === 'demo@vitawallet.io' && body.password === 'password123') {
      return HttpResponse.json({
        token: 'test-token-123',
        user: { id: 1, email: 'demo@vitawallet.io' },
      })
    }
    return HttpResponse.json(
      { error: 'Invalid email or password', code: 'INVALID_CREDENTIALS' },
      { status: 401 },
    )
  }),

  http.get(`${BASE}/balances`, () => {
    return HttpResponse.json({
      balances: [
        { currency: 'usd',  amount: '5000.00000000',     type: 'fiat' },
        { currency: 'clp',  amount: '4500000.00000000',  type: 'fiat' },
        { currency: 'btc',  amount: '0.05000000',         type: 'crypto' },
        { currency: 'usdc', amount: '1000.00000000',      type: 'crypto' },
        { currency: 'usdt', amount: '500.00000000',       type: 'crypto' },
      ],
    })
  }),

  http.get(`${BASE}/prices`, () => {
    return HttpResponse.json({
      prices: [
        { base: 'btc',  quote: 'clp', buy_rate: '60000000.00', sell_rate: '59400000.00' },
        { base: 'usdc', quote: 'clp', buy_rate: '960.00',      sell_rate: '950.00' },
        { base: 'usdt', quote: 'clp', buy_rate: '958.00',      sell_rate: '948.00' },
      ],
      cached: false,
      fetched_at: new Date().toISOString(),
    })
  }),

  http.get(`${BASE}/exchanges`, ({ request }) => {
    const url = new URL(request.url)
    const status = url.searchParams.get('status')
    const exchanges = [
      {
        id: 1, from_currency: 'clp', to_currency: 'btc',
        from_amount: '1000000.00', to_amount: '0.01666667',
        locked_rate: '60000000.00', status: 'completed',
        idempotency_key: null, failure_reason: null,
        executed_at: new Date().toISOString(), created_at: new Date().toISOString(),
      },
      {
        id: 2, from_currency: 'clp', to_currency: 'usdc',
        from_amount: '500000.00', to_amount: null,
        locked_rate: '960.00', status: 'pending',
        idempotency_key: null, failure_reason: null,
        executed_at: null, created_at: new Date().toISOString(),
      },
    ]
    const filtered = status ? exchanges.filter(e => e.status === status) : exchanges
    return HttpResponse.json({
      exchanges: filtered,
      pagination: { page: 1, pages: 1, count: filtered.length, items: 20 },
    })
  }),

  http.post(`${BASE}/exchanges`, async ({ request }) => {
    const body = await request.json() as { exchange: { from_currency: string; to_currency: string; from_amount: string } }
    const { exchange } = body
    return HttpResponse.json({
      exchange: {
        id: 3,
        from_currency: exchange.from_currency,
        to_currency: exchange.to_currency,
        from_amount: exchange.from_amount,
        to_amount: null,
        locked_rate: '60000000.00',
        status: 'pending',
        idempotency_key: null,
        failure_reason: null,
        executed_at: null,
        created_at: new Date().toISOString(),
      },
    }, { status: 202 })
  }),
]
