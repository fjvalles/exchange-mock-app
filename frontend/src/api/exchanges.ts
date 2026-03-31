import { apiClient } from './client'
import type { Exchange, ExchangesResponse, ExchangeStatus } from '../types/api'

export interface CreateExchangeParams {
  from_currency: string
  to_currency: string
  from_amount: string
  idempotencyKey?: string
}

export async function fetchExchanges(params?: {
  status?: ExchangeStatus
  page?: number
}): Promise<ExchangesResponse> {
  const { data } = await apiClient.get<ExchangesResponse>('/exchanges', { params })
  return data
}

export async function createExchange(params: CreateExchangeParams): Promise<{ exchange: Exchange }> {
  const headers: Record<string, string> = {}
  if (params.idempotencyKey) {
    headers['Idempotency-Key'] = params.idempotencyKey
  }
  const { data } = await apiClient.post<{ exchange: Exchange }>(
    '/exchanges',
    { exchange: { from_currency: params.from_currency, to_currency: params.to_currency, from_amount: params.from_amount } },
    { headers },
  )
  return data
}
