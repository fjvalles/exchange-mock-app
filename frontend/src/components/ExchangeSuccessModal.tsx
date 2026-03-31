import successImage from '../assets/successful_exchange.png'
import styles from './ExchangeSuccessModal.module.css'

interface Props {
  toCurrency: string
  onClose: () => void
}

export function ExchangeSuccessModal({ toCurrency, onClose }: Props) {
  return (
    <div className={styles.overlay} onClick={onClose}>
      <div className={styles.modal} onClick={(e) => e.stopPropagation()}>
        <button className={styles.closeBtn} onClick={onClose} aria-label="Cerrar">
          ×
        </button>

        <div className={styles.illustration}>
          <img src={successImage} alt="Intercambio exitoso" />
        </div>

        <h2 className={styles.title}>¡Intercambio exitoso!</h2>
        <p className={styles.subtitle}>
          Ya cuentas con los {toCurrency.toUpperCase()} en tu saldo.
        </p>
      </div>
    </div>
  )
}
