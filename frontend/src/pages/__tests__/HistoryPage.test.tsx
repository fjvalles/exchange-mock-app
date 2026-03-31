import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '../../contexts/AuthContext'
import { HistoryPage } from '../HistoryPage'

function renderHistoryPage() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter>
          <HistoryPage />
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>,
  )
}

describe('HistoryPage', () => {
  it('renders exchange list', async () => {
    renderHistoryPage()
    await waitFor(() => {
      expect(screen.getAllByRole('row').length).toBeGreaterThan(1)
    })
  })

  it('renders status filter tabs', () => {
    renderHistoryPage()
    expect(screen.getByRole('tab', { name: 'Todos' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Completados' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Pendientes' })).toBeInTheDocument()
  })

  it('filters by status when tab clicked', async () => {
    const user = userEvent.setup()
    renderHistoryPage()

    await waitFor(() => screen.getAllByRole('row').length > 1)

    await user.click(screen.getByRole('tab', { name: 'Completados' }))

    await waitFor(() => {
      const badges = screen.getAllByText('completed')
      expect(badges.length).toBeGreaterThan(0)
    })
  })
})
