import { apiClient } from './client'
import type { PricesResponse } from '../types/api'

export async function fetchPrices(): Promise<PricesResponse> {
  const { data } = await apiClient.get<PricesResponse>('/prices')
  return data
}
