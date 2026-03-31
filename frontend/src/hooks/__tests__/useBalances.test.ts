import { renderHook, waitFor } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { createElement } from 'react'
import { useBalances } from '../useBalances'

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return ({ children }: { children: React.ReactNode }) =>
    createElement(QueryClientProvider, { client: queryClient }, children)
}

describe('useBalances', () => {
  it('returns balances array on success', async () => {
    const { result } = renderHook(() => useBalances(), { wrapper: createWrapper() })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))

    expect(result.current.data).toHaveLength(5)
    expect(result.current.data?.[0]).toMatchObject({ currency: 'usd', type: 'fiat' })
  })

  it('returns error state on API failure', async () => {
    const { server } = await import('../../mocks/server')
    const { http, HttpResponse } = await import('msw')

    server.use(
      http.get('http://localhost:3000/api/v1/balances', () =>
        HttpResponse.json({ error: 'Unauthorized', code: 'UNAUTHORIZED' }, { status: 401 }),
      ),
    )

    const { result } = renderHook(() => useBalances(), { wrapper: createWrapper() })
    await waitFor(() => expect(result.current.isError).toBe(true))
  })
})
