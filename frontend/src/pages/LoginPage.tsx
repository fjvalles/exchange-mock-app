import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { login } from '../api/auth'
import styles from './LoginPage.module.css'

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

function EyeIcon({ open }: { open: boolean }) {
  if (open) {
    return (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
        <circle cx="12" cy="12" r="3"/>
      </svg>
    )
  }
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24"/>
      <line x1="1" y1="1" x2="23" y2="23"/>
    </svg>
  )
}

function CheckIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12"/>
    </svg>
  )
}

function LoginIllustration() {
  return (
    <div className={styles.illustration} aria-hidden="true">
      <img src="/amico.png" alt="Login Illustration" style={{ maxWidth: '100%', maxHeight: '80vh', objectFit: 'contain' }} />
    </div>
  )
}

export function LoginPage() {
  const [email, setEmail]         = useState('')
  const [password, setPassword]   = useState('')
  const [showPass, setShowPass]   = useState(false)
  const [error, setError]         = useState<string | null>(null)
  const [loading, setLoading]     = useState(false)
  const { setAuth } = useAuth()
  const navigate = useNavigate()

  const emailValid = isValidEmail(email)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!emailValid) {
      setError('El formato del correo no es válido')
      return
    }

    setLoading(true)
    try {
      const data = await login(email, password)
      setAuth(data.token, data.user)
      navigate('/dashboard')
    } catch (err) {
      setError('El usuario o la contraseña no existen')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={styles.page}>
      <div className={styles.formSection}>
        <h1 className={styles.title}>Iniciar sesión</h1>

        <form onSubmit={handleSubmit} className={styles.form} noValidate>

          {/* Email */}
          <div className={styles.field}>
            <label htmlFor="email">Correo electrónico</label>
            <div className={styles.inputWrapper}>
              <input
                id="email"
                type="email"
                placeholder="correo@ejemplo.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
                className={emailValid && email ? styles.inputValid : ''}
              />
              {emailValid && email && (
                <span className={styles.inputIcon}><CheckIcon /></span>
              )}
            </div>
            {email.length > 0 && !emailValid && (
               <p className={styles.error} style={{ marginTop: '0.25rem' }}>El formato del correo no es válido</p>
            )}
          </div>

          {/* Password */}
          <div className={styles.field}>
            <label htmlFor="password">Contraseña</label>
            <div className={styles.inputWrapper}>
              <input
                id="password"
                type={showPass ? 'text' : 'password'}
                placeholder="Escribe tu contraseña"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                className={styles.eyeBtn}
                onClick={() => setShowPass(v => !v)}
                aria-label={showPass ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                <EyeIcon open={showPass} />
              </button>
            </div>
            <button type="button" className={styles.forgotLink}>
              ¿Olvidaste tu contraseña?
            </button>
          </div>

          {error && (
            <p role="alert" className={styles.error}>{error}</p>
          )}

          <button
            type="submit"
            className={styles.submitBtn}
            disabled={loading || !email || !password || !emailValid}
          >
            {loading ? 'Iniciando sesión...' : 'Iniciar sesión'}
          </button>
        </form>
      </div>

      <div className={styles.imageSection}>
        <LoginIllustration />
      </div>
    </div>
  )
}
