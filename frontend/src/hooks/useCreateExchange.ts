import { useMutation, useQueryClient } from '@tanstack/react-query'
import { createExchange } from '../api/exchanges'
import type { CreateExchangeParams } from '../api/exchanges'

export function useCreateExchange() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (params: Omit<CreateExchangeParams, 'idempotencyKey'>) =>
      createExchange({
        ...params,
        idempotencyKey: crypto.randomUUID(),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['balances'] })
      queryClient.invalidateQueries({ queryKey: ['exchanges'] })
    },
  })
}
