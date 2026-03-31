require "rails_helper"

RSpec.describe Balance, type: :model do
  subject(:balance) { build(:balance) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_inclusion_of(:currency).in_array(Balance::CURRENCIES) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than_or_equal_to(0) }
  end

  describe "constants" do
    it "defines FIAT currencies" do
      expect(Balance::FIAT).to eq(%w[usd clp])
    end

    it "defines CRYPTO currencies" do
      expect(Balance::CRYPTO).to eq(%w[btc usdc usdt])
    end
  end

  describe "money precision" do
    it "stores amount as BigDecimal" do
      balance = create(:balance, amount: "12345.12345678")
      expect(balance.reload.amount).to be_a(BigDecimal)
      expect(balance.amount.to_s("F")).to eq("12345.12345678")
    end

    it "prevents negative amounts at DB level" do
      balance = create(:balance)
      expect {
        balance.update_column(:amount, -1)
      }.to raise_error(ActiveRecord::StatementInvalid, /chk_balances_non_negative/)
    end
  end

  describe "#fiat? / #crypto?" do
    it "returns true for fiat currencies" do
      expect(build(:balance, :usd)).to be_fiat
      expect(build(:balance, :clp)).to be_fiat
    end

    it "returns true for crypto currencies" do
      expect(build(:balance, :btc)).to be_crypto
      expect(build(:balance, :usdc)).to be_crypto
    end
  end

  describe "uniqueness" do
    it "enforces one balance per user per currency" do
      user = create(:user)
      create(:balance, user: user, currency: "btc")
      duplicate = build(:balance, user: user, currency: "btc")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
