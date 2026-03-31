import { useState } from 'react'
import { useExchanges } from '../hooks/useExchanges'
import type { ExchangeStatus } from '../types/api'
import styles from './HistoryPage.module.css'

const STATUS_TABS: { value: ExchangeStatus | undefined; label: string }[] = [
  { value: undefined,    label: 'Todos' },
  { value: 'completed',  label: 'Completados' },
  { value: 'pending',    label: 'Pendientes' },
  { value: 'rejected',   label: 'Rechazados' },
]

const STATUS_COLORS: Record<ExchangeStatus, string> = {
  completed: styles.completed,
  pending:   styles.pending,
  rejected:  styles.rejected,
}

export function HistoryPage() {
  const [status, setStatus] = useState<ExchangeStatus | undefined>(undefined)
  const [page, setPage]     = useState(1)

  const { data, isLoading, isError } = useExchanges(status, page)

  const handleStatusChange = (s: ExchangeStatus | undefined) => {
    setStatus(s)
    setPage(1)
  }

  const displayAmount = (valStr: string, curStr: string) => {
    const valNum = parseFloat(valStr);
    const isFiat = ['usd', 'clp'].includes(curStr.toLowerCase());
    const formatted = valNum.toLocaleString('es-CL', {
      minimumFractionDigits: isFiat ? 2 : 2,
      maximumFractionDigits: isFiat ? 2 : 8
    });
    return `${isFiat ? '$ ' : ''}${formatted} ${curStr.toUpperCase()}`;
  }

  return (
    <div className={styles.page}>
      <h2 className={styles.title}>Historial de intercambios</h2>

      <div className={styles.tabs} role="tablist">
        {STATUS_TABS.map((tab) => (
          <button
            key={tab.label}
            role="tab"
            aria-selected={status === tab.value}
            className={`${styles.tab} ${status === tab.value ? styles.activeTab : ''}`}
            onClick={() => handleStatusChange(tab.value)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {isLoading && <p className={styles.loading}>Cargando...</p>}

      {isError && (
        <p role="alert" className={styles.error}>
          Error al cargar el historial.
        </p>
      )}

      {!isLoading && !isError && data?.exchanges.length === 0 && (
        <p className={styles.emptyState}>Sin transacciones para este filtro.</p>
      )}

      {!isLoading && !isError && (data?.exchanges.length ?? 0) > 0 && (
        <>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>ID</th>
                <th>De</th>
                <th>A</th>
                <th>Monto enviado</th>
                <th>Monto recibido</th>
                <th>Estado</th>
                <th>Fecha</th>
              </tr>
            </thead>
            <tbody>
              {data?.exchanges.map((exchange) => (
                <tr key={exchange.id}>
                  <td>#{exchange.id}</td>
                  <td>{exchange.from_currency.toUpperCase()}</td>
                  <td>{exchange.to_currency.toUpperCase()}</td>
                  <td>{displayAmount(exchange.from_amount, exchange.from_currency)}</td>
                  <td>{exchange.to_amount ? displayAmount(exchange.to_amount, exchange.to_currency) : '—'}</td>
                  <td>
                    <span className={`${styles.badge} ${STATUS_COLORS[exchange.status]}`}>
                      {exchange.status}
                    </span>
                  </td>
                  <td>{new Date(exchange.created_at).toLocaleDateString('es-CL')}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {(data?.pagination.pages ?? 1) > 1 && (
            <div className={styles.pagination}>
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className={styles.pageBtn}
              >
                ← Anterior
              </button>
              <span className={styles.pageInfo}>
                Página {page} de {data?.pagination.pages}
              </span>
              <button
                onClick={() => setPage((p) => p + 1)}
                disabled={page === (data?.pagination.pages ?? 1)}
                className={styles.pageBtn}
              >
                Siguiente →
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
