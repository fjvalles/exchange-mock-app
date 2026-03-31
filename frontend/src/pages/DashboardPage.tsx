import { useState } from 'react'
import { useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { useBalances } from '../hooks/useBalances'
import { useExchanges } from '../hooks/useExchanges'
import { ExchangeSuccessModal } from '../components/ExchangeSuccessModal'
import coinIcon from '../assets/coin.png'
import styles from './DashboardPage.module.css'


const CURRENCY_ICONS: Record<string, string> = {
  clp: 'https://api.iconify.design/circle-flags:cl.svg',
  usd: 'https://api.iconify.design/circle-flags:us.svg',
  btc: 'https://api.iconify.design/logos:bitcoin.svg',
  usdc: 'https://api.iconify.design/cryptocurrency-color:usdc.svg',
  usdt: 'https://api.iconify.design/cryptocurrency-color:usdt.svg',
}

const STATUS_TABS = [
  { value: undefined,   label: 'Todos' },
  { value: 'completed', label: 'Completados' },
  { value: 'pending',   label: 'Pendientes' },
  { value: 'rejected',  label: 'Rechazados' },
] as const

type StatusValue = typeof STATUS_TABS[number]['value']

export function DashboardPage() {
  const { user } = useAuth()
  const { data: balances, isLoading: balancesLoading } = useBalances()
  const location = useLocation()
  const successState = location.state as { showSuccess?: boolean; toCurrency?: string } | null
  const [showModal, setShowModal] = useState(!!successState?.showSuccess)

  const [historyStatus, setHistoryStatus] = useState<StatusValue>(undefined)
  const [historyPage, setHistoryPage]     = useState(1)

  const { data: exchangesData, isLoading: exchangesLoading } = useExchanges(historyStatus, historyPage)

  const handleStatusChange = (s: StatusValue) => {
    setHistoryStatus(s)
    setHistoryPage(1)
  }

  const displayAmount = (valStr: string, curStr: string) => {
    const valNum = parseFloat(valStr)
    const isFiat = ['usd', 'clp'].includes(curStr.toLowerCase())
    return `${isFiat ? '$ ' : ''}${valNum.toLocaleString('es-CL', {
      minimumFractionDigits: 2,
      maximumFractionDigits: isFiat ? 2 : 4,
    })} ${curStr.toUpperCase()}`
  }

  return (
    <div className={styles.page}>
      {showModal && successState?.toCurrency && (
        <ExchangeSuccessModal
          toCurrency={successState.toCurrency}
          onClose={() => setShowModal(false)}
        />
      )}

      <div className={styles.header}>
        <img src={coinIcon} alt="" className={styles.headerIcon} />
        <h2>
          ¡Hola <span className={styles.username}>{user?.email.split('@')[0]}!</span>
        </h2>
      </div>

      <section>
        <h3 className={styles.sectionTitle}>Mis saldos</h3>
        {balancesLoading ? (
          <p>Cargando saldos...</p>
        ) : (
          <div className={styles.balancesGrid}>
            {balances?.map((balance) => (
              <div key={balance.currency} className={styles.balanceCard}>
                <div className={styles.balanceCardHeader}>
                  <span>{balance.currency.toUpperCase()}</span>
                  {CURRENCY_ICONS[balance.currency] ? (
                    <img src={CURRENCY_ICONS[balance.currency]} className={styles.currencyIconImage} alt="" />
                  ) : (
                    <span className={styles.currencyIcon}>{balance.currency.toUpperCase()}</span>
                  )}
                </div>
                <p className={styles.balanceAmount}>
                  {balance.type === 'fiat' ? '$ ' : ''}
                  {parseFloat(balance.amount).toLocaleString('es-CL', {
                    maximumFractionDigits: 20,
                  })}
                </p>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className={styles.historySection}>
        <h3 className={styles.sectionTitle}>Historial</h3>

        <div className={styles.tabs} role="tablist">
          {STATUS_TABS.map((tab) => (
            <button
              key={tab.label}
              role="tab"
              aria-selected={historyStatus === tab.value}
              className={`${styles.tab} ${historyStatus === tab.value ? styles.activeTab : ''}`}
              onClick={() => handleStatusChange(tab.value)}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {exchangesLoading ? (
          <p>Cargando historial...</p>
        ) : exchangesData?.exchanges.length === 0 ? (
          <p className={styles.emptyState}>Sin transacciones para este filtro.</p>
        ) : (
          <>
            <ul className={styles.historyList}>
              {exchangesData?.exchanges.map((exchange) => (
                <li key={exchange.id} className={styles.historyItem}>
                  <span className={styles.historyTypeLabel}>
                    Intercambiaste
                  </span>
                  <span className={styles.historyAmountValue}>
                    {exchange.to_amount
                      ? displayAmount(exchange.to_amount, exchange.to_currency)
                      : '—'}
                  </span>
                </li>
              ))}
            </ul>

            {(exchangesData?.pagination.pages ?? 1) > 1 && (
              <div className={styles.pagination}>
                <button
                  className={styles.pageBtn}
                  onClick={() => setHistoryPage((p: number) => Math.max(1, p - 1))}
                  disabled={historyPage === 1}
                >
                  ← Anterior
                </button>
                <span className={styles.pageInfo}>
                  Página {historyPage} de {exchangesData?.pagination.pages}
                </span>
                <button
                  className={styles.pageBtn}
                  onClick={() => setHistoryPage((p) => p + 1)}
                  disabled={historyPage === (exchangesData?.pagination.pages ?? 1)}
                >
                  Siguiente →
                </button>
              </div>
            )}
          </>
        )}
      </section>
    </div>
  )
}
