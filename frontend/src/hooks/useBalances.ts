import { useQuery } from '@tanstack/react-query'
import { fetchBalances } from '../api/balances'

export function useBalances() {
  return useQuery({
    queryKey: ['balances'],
    queryFn: fetchBalances,
    staleTime: 30_000,
    select: (data) => data.balances,
  })
}
