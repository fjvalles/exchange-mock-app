import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import styles from './Sidebar.module.css'

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Inicio' },
  { to: '/exchange',  label: 'Intercambiar' },
  { to: '/history',   label: 'Historial' },
]

export function Sidebar() {
  const { logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <nav className={styles.sidebar}>

      <ul className={styles.nav}>
        {NAV_ITEMS.map(({ to, label }) => (
          <li key={to}>
            <NavLink
              to={to}
              className={({ isActive }) =>
                `${styles.navLink} ${isActive ? styles.active : ''}`
              }
            >
              {label}
            </NavLink>
          </li>
        ))}
      </ul>
      <button className={styles.logoutBtn} onClick={handleLogout}>
        Cerrar sesión
      </button>
    </nav>
  )
}
