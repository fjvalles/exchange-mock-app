class Balance < ApplicationRecord
  include MoneyValue

  FIAT    = %w[usd clp].freeze
  CRYPTO  = %w[btc usdc usdt].freeze
  CURRENCIES = (FIAT + CRYPTO).freeze

  monetize_attributes :amount

  belongs_to :user

  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  def fiat?
    FIAT.include?(currency)
  end

  def crypto?
    CRYPTO.include?(currency)
  end
end
