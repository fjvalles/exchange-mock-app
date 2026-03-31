import { renderHook, waitFor, act } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createElement } from 'react'
import { useCreateExchange } from '../useCreateExchange'

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })
  return ({ children }: { children: React.ReactNode }) =>
    createElement(QueryClientProvider, { client: queryClient }, children)
}

describe('useCreateExchange', () => {
  it('calls API with correct payload and returns exchange', async () => {
    const { result } = renderHook(() => useCreateExchange(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate({
        from_currency: 'clp',
        to_currency: 'btc',
        from_amount: '1000000',
      })
    })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data?.exchange.status).toBe('pending')
    expect(result.current.data?.exchange.from_currency).toBe('clp')
  })

  it('generates a unique idempotency key per call', async () => {
    const { http, HttpResponse } = await import('msw')
    const { server } = await import('../../mocks/server')
    const capturedKeys: string[] = []

    server.use(
      http.post('http://localhost:3000/api/v1/exchanges', ({ request }) => {
        const key = request.headers.get('Idempotency-Key')
        if (key) capturedKeys.push(key)
        return HttpResponse.json({
          exchange: {
            id: 99, from_currency: 'clp', to_currency: 'btc',
            from_amount: '1000000', to_amount: null, locked_rate: '60000000',
            status: 'pending', idempotency_key: key, failure_reason: null,
            executed_at: null, created_at: new Date().toISOString(),
          },
        }, { status: 202 })
      }),
    )

    const wrapper = createWrapper()
    const { result: r1 } = renderHook(() => useCreateExchange(), { wrapper })
    const { result: r2 } = renderHook(() => useCreateExchange(), { wrapper })

    act(() => { r1.current.mutate({ from_currency: 'clp', to_currency: 'btc', from_amount: '1000000' }) })
    await waitFor(() => expect(r1.current.isSuccess).toBe(true))

    act(() => { r2.current.mutate({ from_currency: 'clp', to_currency: 'btc', from_amount: '1000000' }) })
    await waitFor(() => expect(r2.current.isSuccess).toBe(true))

    expect(capturedKeys).toHaveLength(2)
    expect(capturedKeys[0]).not.toBe(capturedKeys[1])
  })

  it('exposes error on API failure', async () => {
    const { http, HttpResponse } = await import('msw')
    const { server } = await import('../../mocks/server')

    server.use(
      http.post('http://localhost:3000/api/v1/exchanges', () =>
        HttpResponse.json(
          { error: 'Insufficient balance', code: 'INSUFFICIENT_BALANCE' },
          { status: 422 },
        ),
      ),
    )

    const { result } = renderHook(() => useCreateExchange(), { wrapper: createWrapper() })

    act(() => {
      result.current.mutate({ from_currency: 'clp', to_currency: 'btc', from_amount: '99999999' })
    })

    await waitFor(() => expect(result.current.isError).toBe(true))
  })
})
