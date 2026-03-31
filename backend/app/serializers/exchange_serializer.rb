class ExchangeSerializer < Blueprinter::Base
  fields :id, :from_currency, :to_currency, :status, :idempotency_key,
         :failure_reason, :executed_at, :created_at

  field :from_amount do |exchange|
    exchange.from_amount.to_s("F")
  end

  field :to_amount do |exchange|
    exchange.to_amount&.to_s("F")
  end

  field :locked_rate do |exchange|
    exchange.locked_rate.to_s("F")
  end
end
