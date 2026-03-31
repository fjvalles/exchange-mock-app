class User < ApplicationRecord
  has_secure_password

  has_many :balances, dependent: :destroy
  has_many :exchanges, dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :api_token, presence: true, uniqueness: true

  before_validation :normalize_email
  before_validation :generate_api_token, on: :create

  def self.find_by_token(token)
    find_by(api_token: token)
  end

  private

  def normalize_email
    self.email = email&.strip&.downcase
  end

  def generate_api_token
    loop do
      self.api_token = SecureRandom.hex(32)
      break unless self.class.exists?(api_token: api_token)
    end
  end
end
