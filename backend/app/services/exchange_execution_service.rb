class ExchangeExecutionService
  InsufficientBalanceError = Class.new(StandardError)

  def initialize(exchange:)
    @exchange = exchange
  end

  def call
    ActiveRecord::Base.transaction do
      from_balance = @exchange.user.balances.lock.find_by!(currency: @exchange.from_currency)
      to_balance   = @exchange.user.balances.lock.find_by!(currency: @exchange.to_currency)

      raise InsufficientBalanceError if from_balance.amount < @exchange.from_amount

      to_amount = compute_to_amount

      from_balance.update!(amount: from_balance.amount - @exchange.from_amount)
      to_balance.update!(amount: to_balance.amount + to_amount)
      @exchange.update!(
        status:      :completed,
        to_amount:   to_amount,
        executed_at: Time.current
      )
    end
  rescue InsufficientBalanceError
    @exchange.update!(
      status:         :rejected,
      failure_reason: "Insufficient balance at execution time"
    )
  end

  private

  def compute_to_amount
    from  = BigDecimal(@exchange.from_amount.to_s)
    rate  = BigDecimal(@exchange.locked_rate.to_s)

    if Balance::FIAT.include?(@exchange.from_currency)
      (from / rate).round(8)
    else
      (from * rate).round(8)
    end
  end
end
