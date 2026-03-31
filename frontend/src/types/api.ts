export type Currency = 'usd' | 'clp' | 'btc' | 'usdc' | 'usdt'
export type CurrencyType = 'fiat' | 'crypto'
export type ExchangeStatus = 'pending' | 'completed' | 'rejected'

export interface Balance {
  currency: Currency
  amount: string
  type: CurrencyType
}

export interface Price {
  base: Currency
  quote: Currency
  buy_rate: string
  sell_rate: string
}

export interface Exchange {
  id: number
  from_currency: Currency
  to_currency: Currency
  from_amount: string
  to_amount: string | null
  locked_rate: string
  status: ExchangeStatus
  idempotency_key: string | null
  failure_reason: string | null
  executed_at: string | null
  created_at: string
}

export interface PaginationMeta {
  page: number
  pages: number
  count: number
  items: number
}

export interface ApiError {
  error: string
  code: string
  details?: Record<string, string[]>
}

export interface LoginResponse {
  token: string
  user: { id: number; email: string }
}

export interface BalancesResponse {
  balances: Balance[]
}

export interface PricesResponse {
  prices: Price[]
  cached: boolean
  fetched_at: string
}

export interface ExchangesResponse {
  exchanges: Exchange[]
  pagination: PaginationMeta
}
