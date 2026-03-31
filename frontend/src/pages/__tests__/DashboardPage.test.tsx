import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '../../contexts/AuthContext'
import { DashboardPage } from '../DashboardPage'

function renderDashboardPage() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter>
          <DashboardPage />
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>,
  )
}

describe('DashboardPage', () => {
  it('renders balance cards with currencies', async () => {
    renderDashboardPage()
    
    // Check for "Mis Saldos" title
    expect(screen.getByText(/Mis saldos/i)).toBeInTheDocument()

    // Check for CLP, BTC, USD, USDC, USDT balances
    await waitFor(() => {
      expect(screen.getByText('CLP')).toBeInTheDocument()
      expect(screen.getByText('BTC')).toBeInTheDocument()
      expect(screen.getByText('USD')).toBeInTheDocument()
      expect(screen.getByText('USDC')).toBeInTheDocument()
      expect(screen.getByText('USDT')).toBeInTheDocument()
    })
  })

  it('renders navigation cards (Recargar, Transferir, Intercambiar)', () => {
    renderDashboardPage()
    expect(screen.getByText(/Recargar/i)).toBeInTheDocument()
    expect(screen.getByText(/Transferir/i)).toBeInTheDocument()
    expect(screen.getByText(/Intercambiar/i)).toBeInTheDocument()
  })

  it('renders history table items', async () => {
    renderDashboardPage()
    // History should have items from mocks
    await waitFor(() => {
      // In mocks: exchange id: 1 has to_amount: '0.01666667' to_currency: 'btc'
      // displayAmount(0.01666667, 'btc') with maxFractionDigits: 4 -> 0,0167 BTC
      expect(screen.getByText('0,0167 BTC')).toBeInTheDocument()
    })
  })
})
