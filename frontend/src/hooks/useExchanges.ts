import { useQuery } from '@tanstack/react-query'
import { fetchExchanges } from '../api/exchanges'
import type { ExchangeStatus } from '../types/api'

export function useExchanges(status?: ExchangeStatus, page = 1) {
  return useQuery({
    queryKey: ['exchanges', status, page],
    queryFn: () => fetchExchanges({ status, page }),
    placeholderData: (prev) => prev,
  })
}
