class Exchange < ApplicationRecord
  include MoneyValue

  VALID_PAIRS = [
    %w[usd btc], %w[usd usdc], %w[usd usdt], %w[usd clp],
    %w[clp btc], %w[clp usdc], %w[clp usdt], %w[clp usd],
    %w[btc usd], %w[btc clp],
    %w[usdc usd], %w[usdc clp],
    %w[usdt usd], %w[usdt clp]
  ].map(&:freeze).freeze

  monetize_attributes :from_amount, :to_amount, :locked_rate

  enum status: { pending: "pending", completed: "completed", rejected: "rejected" }

  belongs_to :user

  validates :from_currency, :to_currency, :from_amount, :locked_rate, presence: true
  validates :from_amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: statuses.keys }
  validate :currency_pair_is_valid

  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  private

  def currency_pair_is_valid
    pair = [from_currency, to_currency]
    errors.add(:base, :invalid_currency_pair) unless VALID_PAIRS.include?(pair)
  end
end
