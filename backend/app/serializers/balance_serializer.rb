class BalanceSerializer < Blueprinter::Base
  fields :currency, :amount

  field :type do |balance|
    balance.fiat? ? "fiat" : "crypto"
  end

  field :amount do |balance|
    balance.amount.to_s("F")
  end
end
