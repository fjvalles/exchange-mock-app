class Exchange < ApplicationRecord
  include MoneyValue



  monetize_attributes :from_amount, :to_amount, :locked_rate

  enum status: { pending: "pending", completed: "completed", rejected: "rejected" }

  belongs_to :user

  validates :from_currency, :to_currency, :from_amount, :locked_rate, presence: true
  validates :from_amount, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: statuses.keys }
  validate :currencies_must_be_different

  scope :for_user, ->(user) { where(user: user) }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :recent, -> { order(created_at: :desc) }

  private

  def currencies_must_be_different
    if from_currency == to_currency
      errors.add(:to_currency, "must be different from starting currency")
    end
  end
end
