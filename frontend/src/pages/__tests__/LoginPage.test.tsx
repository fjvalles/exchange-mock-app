import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { AuthProvider } from '../../contexts/AuthContext'
import { LoginPage } from '../LoginPage'

function renderLoginPage() {
  const qc = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={qc}>
      <AuthProvider>
        <MemoryRouter>
          <LoginPage />
        </MemoryRouter>
      </AuthProvider>
    </QueryClientProvider>,
  )
}

describe('LoginPage', () => {
  it('renders form fields', () => {
    renderLoginPage()
    expect(screen.getByLabelText(/correo electrónico/i)).toBeInTheDocument()
    // Use placeholder to avoid ambiguity with the show/hide password button aria-label
    expect(screen.getByPlaceholderText(/escribe tu contraseña/i)).toBeInTheDocument()
  })

  it('disables submit button when fields are empty', () => {
    renderLoginPage()
    const submitBtn = screen.getByRole('button', { name: /iniciar sesión/i })
    expect(submitBtn).toBeDisabled()
  })

  it('enables submit button when both fields are filled', async () => {
    const user = userEvent.setup()
    renderLoginPage()

    await user.type(screen.getByLabelText(/correo electrónico/i), 'demo@vitawallet.io')
    await user.type(screen.getByPlaceholderText(/escribe tu contraseña/i), 'password123')

    expect(screen.getByRole('button', { name: /iniciar sesión/i })).not.toBeDisabled()
  })

  it('shows error message on invalid credentials', async () => {
    const user = userEvent.setup()
    renderLoginPage()

    await user.type(screen.getByLabelText(/correo electrónico/i), 'wrong@email.com')
    await user.type(screen.getByPlaceholderText(/escribe tu contraseña/i), 'wrongpassword')
    await user.click(screen.getByRole('button', { name: /iniciar sesión/i }))

    await waitFor(() => {
      expect(screen.getByRole('alert')).toBeInTheDocument()
    })
  })
})
