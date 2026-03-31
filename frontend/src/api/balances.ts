import { apiClient } from './client'
import type { BalancesResponse } from '../types/api'

export async function fetchBalances(): Promise<BalancesResponse> {
  const { data } = await apiClient.get<BalancesResponse>('/balances')
  return data
}
