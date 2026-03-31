require "rails_helper"

RSpec.describe Exchange, type: :model do
  subject(:exchange) { build(:exchange) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:from_currency) }
    it { is_expected.to validate_presence_of(:to_currency) }
    it { is_expected.to validate_presence_of(:from_amount) }
    it { is_expected.to validate_presence_of(:locked_rate) }
    it { is_expected.to validate_numericality_of(:from_amount).is_greater_than(0) }
  end

  describe "status enum" do
    it "defaults to pending" do
      expect(exchange.status).to eq("pending")
    end

    it "transitions to completed" do
      exchange = create(:exchange)
      exchange.completed!
      expect(exchange.reload).to be_completed
    end
  end

  describe "currency pair validation" do
    it "accepts valid pairs" do
      Exchange::VALID_PAIRS.each do |from, to|
        ex = build(:exchange, from_currency: from, to_currency: to)
        expect(ex).to be_valid, "Expected #{from}→#{to} to be valid"
      end
    end

    it "rejects invalid pairs" do
      ex = build(:exchange, from_currency: "btc", to_currency: "usdt")
      expect(ex).not_to be_valid
    end

    it "rejects same-currency pairs" do
      ex = build(:exchange, from_currency: "clp", to_currency: "clp")
      expect(ex).not_to be_valid
    end
  end

  describe "DB constraints" do
    it "enforces valid status values at DB level" do
      exchange = create(:exchange)
      expect {
        exchange.update_column(:status, "invalid_status")
      }.to raise_error(ActiveRecord::StatementInvalid, /chk_exchanges_valid_status/)
    end

    it "enforces positive from_amount at DB level" do
      user = create(:user)
      exchange = build(:exchange, user: user, from_amount: 0)
      expect {
        exchange.save!(validate: false)
      }.to raise_error(ActiveRecord::StatementInvalid, /chk_exchanges_positive_amount/)
    end
  end

  describe "idempotency key uniqueness" do
    it "enforces unique idempotency keys" do
      key = SecureRandom.uuid
      create(:exchange, idempotency_key: key)
      duplicate = build(:exchange, idempotency_key: key)
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows multiple records with NULL idempotency_key" do
      create(:exchange, idempotency_key: nil)
      expect { create(:exchange, idempotency_key: nil) }.not_to raise_error
    end
  end
end
