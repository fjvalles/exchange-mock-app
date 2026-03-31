import { useQuery } from '@tanstack/react-query'
import { fetchPrices } from '../api/prices'

export function usePrices() {
  return useQuery({
    queryKey: ['prices'],
    queryFn: fetchPrices,
    staleTime: 30_000,
    refetchInterval: 60_000,
  })
}
