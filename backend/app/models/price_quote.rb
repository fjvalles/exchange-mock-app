class PriceQuote < ApplicationRecord
  include MoneyValue

  monetize_attributes :buy_rate, :sell_rate

  validates :base, :quote, :buy_rate, :sell_rate, :fetched_at, presence: true

  scope :latest_for, ->(base, quote) {
    where(base: base, quote: quote).order(fetched_at: :desc).first
  }
end
