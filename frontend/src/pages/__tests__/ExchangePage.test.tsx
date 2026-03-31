import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '../../contexts/AuthContext'
import { ExchangePage } from '../ExchangePage'

function renderExchangePage() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter initialEntries={['/exchange']}>
          <Routes>
            <Route path="/exchange" element={<ExchangePage />} />
            <Route path="/dashboard" element={<div>Dashboard Page</div>} />
          </Routes>
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>,
  )
}

describe('ExchangePage', () => {
  it('renders exchange form with title', async () => {
    renderExchangePage()
    expect(screen.getByText('¿Qué deseas intercambiar?')).toBeInTheDocument()
    await waitFor(() => {
      expect(screen.getByText(/Saldo disponible/i)).toBeInTheDocument()
    })
  })

  it('calculates the conversion amount for CLP to BTC', async () => {
    renderExchangePage()
    const user = userEvent.setup()
    
    // Base test for CLP -> BTC (mock rate: 1 BTC = 60,000,000 CLP)
    const inputs = screen.getAllByPlaceholderText('0,00') as HTMLInputElement[]
    const fromInput = inputs[0]
    const toInput   = inputs[1]

    await user.type(fromInput, '1000000') // 1,000,000 CLP

    await waitFor(() => {
      // 1,000,000 / 59,400,000 (buy_rate) = 0.01683502
      expect(toInput.value).toBe('0.01683502')
    })
  })

  it('shows error if exchange amount exceeds balance', async () => {
    renderExchangePage()
    const user = userEvent.setup()
    
    // Balance for CLP in mocks is 4,500,000
    const fromInput = screen.getAllByPlaceholderText('0,00')[0]
    await user.type(fromInput, '5000000')

    await waitFor(() => {
      expect(screen.getByText(/El monto a intercambiar excede tu saldo disponible/i)).toBeInTheDocument()
    })
  })

  it('completes the full flow: Form -> Summary -> Success (navigate)', async () => {
    renderExchangePage()
    const user = userEvent.setup()

    await waitFor(() => screen.getByText(/Saldo disponible/i))
    
    // Input 1,000,000 CLP
    const fromInput = screen.getAllByPlaceholderText('0,00')[0]
    await user.type(fromInput, '1000000')

    // Click "Continuar"
    const continueBtn = screen.getByRole('button', { name: /Continuar/i })
    await user.click(continueBtn)

    // Should be on Summary view
    expect(screen.getByText('Resumen de transacción')).toBeInTheDocument()
    expect(screen.getByText('$ 1.000.000,00 CLP')).toBeInTheDocument()
    expect(screen.getByText(/1 BTC = \$ 60\.000\.000,00 CLP/)).toBeInTheDocument()

    // Click "Intercambiar"
    const exchangeBtn = screen.getByRole('button', { name: /Intercambiar/i })
    await user.click(exchangeBtn)

    // Should navigate to dashboard
    await waitFor(() => {
      expect(screen.getByText('Dashboard Page')).toBeInTheDocument()
    })
  })

  it('allows going back from summary to form', async () => {
    renderExchangePage()
    const user = userEvent.setup()

    await waitFor(() => screen.getByText(/Saldo disponible/i))
    const fromInput = screen.getAllByPlaceholderText('0,00')[0]
    await user.type(fromInput, '1000')
    
    await user.click(screen.getByRole('button', { name: /Continuar/i }))
    expect(screen.getByText('Resumen de transacción')).toBeInTheDocument()

    // Click "Atras" in summary
    await user.click(screen.getByRole('button', { name: /Atrás/i }))
    expect(screen.getByText('¿Qué deseas intercambiar?')).toBeInTheDocument()
  })
})
