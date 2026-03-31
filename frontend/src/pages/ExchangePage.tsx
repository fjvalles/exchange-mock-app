import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useBalances } from '../hooks/useBalances'
import { usePrices } from '../hooks/usePrices'
import { useCreateExchange } from '../hooks/useCreateExchange'
import { extractApiError } from '../api/client'
import type { Currency } from '../types/api'
import styles from './ExchangePage.module.css'

const CURRENCIES: { value: Currency; label: string; icon: string }[] = [
  { value: 'clp',  label: 'CLP', icon: 'https://api.iconify.design/circle-flags:cl.svg' },
  { value: 'usd',  label: 'USD', icon: 'https://api.iconify.design/circle-flags:us.svg' },
  { value: 'btc',  label: 'BTC', icon: 'https://api.iconify.design/logos:bitcoin.svg' },
  { value: 'usdc', label: 'USDC', icon: 'https://api.iconify.design/cryptocurrency-color:usdc.svg' },
  { value: 'usdt', label: 'USDT', icon: 'https://api.iconify.design/cryptocurrency-color:usdt.svg' },
]

function CurrencySelect({
  value, onChange, exclude,
}: { value: Currency; onChange: (v: Currency) => void; exclude?: Currency }) {
  const current = CURRENCIES.find(c => c.value === value);
  return (
    <div className={styles.currencySelectWrapper}>
      {current && (current.icon.startsWith('http') || current.icon.includes('.svg')) ? (
        <img src={current.icon} className={styles.currencyIcon} alt={current.label} />
      ) : (
        <span className={styles.currencyEmoji}>{current?.icon}</span>
      )}
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as Currency)}
        className={styles.select}
      >
        {CURRENCIES.filter((c) => c.value !== exclude).map((c) => (
          <option key={c.value} value={c.value}>
            {c.label}
          </option>
        ))}
      </select>
    </div>
  )
}

export function ExchangePage() {
  const navigate = useNavigate()
  const [fromCurrency, setFromCurrency] = useState<Currency>('clp')
  const [toCurrency, setToCurrency]     = useState<Currency>('btc')
  const [amount, setAmount]             = useState('')
  const [inputMode, setInputMode]       = useState<'from' | 'to'>('from')
  const [error, setError]               = useState<string | null>(null)

  const { data: balances }  = useBalances()
  const { data: priceData } = usePrices()
  const createExchange      = useCreateExchange()

  const fromBalance = balances?.find((b) => b.currency === fromCurrency)
  const availableNum = parseFloat(fromBalance?.amount || '0')

  const calculateConversion = (val: number, from: Currency, to: Currency) => {
    if (from === to) return val;
    
    // Simulate USD price since it's not present in backend
    const getVirtualRate = (c: Currency, isBuy: boolean) => {
      if (c === 'clp') return 1;
      if (c === 'usd') return isBuy ? 920 : 940; // mock USD/CLP prices
      
      const p = priceData?.prices?.find(x => x.base === c && x.quote === 'clp');
      if (p) return isBuy ? parseFloat(p.buy_rate) : parseFloat(p.sell_rate);
      
      // Fallback if priceData is empty/failing
      if (c === 'btc') return isBuy ? 60000000 : 61000000;
      if (c === 'usdt') return isBuy ? 920 : 940;
      if (c === 'usdc') return isBuy ? 920 : 940;

      return null;
    }

    const fromRateClp = getVirtualRate(from, true);  // selling from -> clp
    const toRateClp   = getVirtualRate(to, false);   // buying to <- clp

    if (!fromRateClp || !toRateClp) return null;

    const clpAmount = val * fromRateClp;
    return clpAmount / toRateClp;
  }

  const formatAmount = (val: number, cur: Currency) => {
    if (['usd', 'clp'].includes(cur)) return val.toFixed(2);
    return val.toFixed(8).replace(/\.?0+$/, '') || '0';
  }

  let calculatedFrom = '';
  let calculatedTo = '';

  if (amount && parseFloat(amount) > 0) {
    const val = parseFloat(amount);
    
    if (inputMode === 'from') {
      calculatedFrom = amount;
      const calcObj = calculateConversion(val, fromCurrency, toCurrency);
      calculatedTo = calcObj !== null ? formatAmount(calcObj, toCurrency) : '';
    } else {
      calculatedTo = amount;
      const calcObj = calculateConversion(val, toCurrency, fromCurrency);
      calculatedFrom = calcObj !== null ? formatAmount(calcObj, fromCurrency) : '';
    }
  } else {
    if (inputMode === 'from') calculatedFrom = amount;
    else calculatedTo = amount;
  }

  const amountNum = parseFloat(calculatedFrom || '0')
  const exceedsBalance = amountNum > availableNum
  const isValidAmount = amountNum > 0 && !exceedsBalance
  const remainingBalance = availableNum - (amountNum > 0 ? amountNum : 0)

  const [step, setStep] = useState<'form' | 'summary'>('form')

  const handleContinue = () => {
    if (!isValidAmount || exceedsBalance) return
    setError(null)
    setStep('summary')
  }

  const handleExchange = async () => {
    setError(null)
    try {
      await createExchange.mutateAsync({ 
        from_currency: fromCurrency, 
        to_currency: toCurrency, 
        from_amount: calculatedFrom 
      })
      navigate('/dashboard', { state: { showSuccess: true, toCurrency } })
    } catch (err) {
      setError(extractApiError(err).error)
    }
  }

  const canSubmit = isValidAmount && !createExchange.isPending

  const displayAmount = (valNum: number, cur: Currency) => {
    const isFiat = ['usd', 'clp'].includes(cur);
    const formatted = valNum.toLocaleString('es-CL', {
      minimumFractionDigits: isFiat ? 2 : 2, // matching the figma decimal comma style
      maximumFractionDigits: isFiat ? 2 : 8
    });
    return `${isFiat ? '$ ' : ''}${formatted} ${cur.toUpperCase()}`;
  }

  const getExchangeRateText = () => {
    // Always show the rate from the perspective of the larger-valued currency
    // so the number shown is always >= 1 (more readable).
    const FIAT = ['usd', 'clp']
    const isCryptoTo = !FIAT.includes(toCurrency)

    if (isCryptoTo) {
      // e.g. CLP→BTC: show "1 BTC = X CLP"
      const rateNum = calculateConversion(1, toCurrency, fromCurrency) || 0
      return `1 ${toCurrency.toUpperCase()} = ${displayAmount(rateNum, fromCurrency)}`
    } else {
      // fiat→fiat or crypto→fiat: show inverse if result < 1
      const direct = calculateConversion(1, fromCurrency, toCurrency) || 0
      if (direct >= 1) {
        return `1 ${fromCurrency.toUpperCase()} = ${displayAmount(direct, toCurrency)}`
      } else {
        // e.g. CLP→USD gives 0.001 — show "1 USD = X CLP" instead
        const inverse = calculateConversion(1, toCurrency, fromCurrency) || 0
        return `1 ${toCurrency.toUpperCase()} = ${displayAmount(inverse, fromCurrency)}`
      }
    }
  }

  return (
    <div className={styles.page}>
      {step === 'form' ? (
        <>
          <h2 className={styles.title}>¿Qué deseas intercambiar?</h2>

          {fromBalance && (
            <p className={styles.balanceHint} style={{ color: exceedsBalance ? '#dc2626' : undefined }}>
              Saldo disponible:{fromBalance.type === 'fiat' ? ' $' : ''} 
              {remainingBalance.toLocaleString('es-CL', {
                minimumFractionDigits: ['usd','clp'].includes(fromCurrency) ? 2 : 8,
                maximumFractionDigits: ['usd','clp'].includes(fromCurrency) ? 2 : 8,
              })} {fromCurrency.toUpperCase()}
            </p>
          )}

          <div className={styles.formGroup}>
            <label className={styles.label}>Monto a intercambiar</label>
            <div className={styles.inputRow}>
              <CurrencySelect value={fromCurrency} onChange={setFromCurrency} exclude={toCurrency} />
              <input
                type="number"
                className={styles.amountInput}
                placeholder="0,00"
                value={calculatedFrom}
                min="0"
                step="any"
                onChange={(e) => {
                  setInputMode('from');
                  setAmount(e.target.value);
                }}
              />
            </div>
            {exceedsBalance && (
              <span className={styles.errorText} style={{ color: '#dc2626', fontSize: '0.8rem', display: 'block', marginTop: '0.5rem' }}>
                El monto a intercambiar excede tu saldo disponible.
              </span>
            )}
          </div>

          <div className={styles.formGroup}>
            <label className={styles.label}>Quiero recibir</label>
            <div className={styles.inputRow}>
              <CurrencySelect value={toCurrency} onChange={setToCurrency} exclude={fromCurrency} />
              <input
                type="number"
                className={styles.amountInput}
                placeholder="0,00"
                value={calculatedTo}
                min="0"
                step="any"
                onChange={(e) => {
                  setInputMode('to');
                  setAmount(e.target.value);
                }}
              />
            </div>
          </div>

          {error && <p role="alert" className={styles.error}>{error}</p>}

          <div className={styles.actions}>
            <button className={styles.backBtn} onClick={() => navigate('/dashboard')}>
              Atrás
            </button>
            <button
              className={styles.submitBtn}
              data-active={canSubmit}
              disabled={!canSubmit}
              onClick={handleContinue}
            >
              Continuar
            </button>
          </div>
        </>
      ) : (
        <>
          <div className={styles.summaryHeader}>
            <button className={styles.backArrowBtn} onClick={() => setStep('form')} aria-label="Volver">
               ←
            </button>
            <h2 className={styles.summaryTitle}>Resumen de transacción</h2>
          </div>

          <div className={styles.summaryBox}>
            <div className={styles.summaryRow}>
              <span className={styles.summaryLabel}>Monto a intercambiar</span>
              <span className={styles.summaryValue}>{displayAmount(parseFloat(calculatedFrom), fromCurrency)}</span>
            </div>
            <div className={styles.summaryRow}>
              <span className={styles.summaryLabel}>Tasa de cambio</span>
              <span className={styles.summaryValue}>{getExchangeRateText()}</span>
            </div>
            <div className={styles.summaryRow}>
              <span className={styles.summaryTotalLabel}>Total a recibir</span>
              <span className={styles.summaryTotalValue}>{displayAmount(parseFloat(calculatedTo), toCurrency)}</span>
            </div>
          </div>

          {error && <p role="alert" className={styles.error} style={{marginTop: '1rem'}}>{error}</p>}

          <div className={styles.summaryActions}>
            <button className={styles.backBtn} onClick={() => setStep('form')}>
              Atrás
            </button>
            <button
              className={styles.submitBtn}
              data-active={true}
              disabled={createExchange.isPending}
              onClick={handleExchange}
            >
              {createExchange.isPending ? 'Procesando...' : 'Intercambiar'}
            </button>
          </div>
        </>
      )}
    </div>
  )
}
