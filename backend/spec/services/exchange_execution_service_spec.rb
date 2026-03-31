require "rails_helper"

RSpec.describe ExchangeExecutionService do
  let(:user)         { create(:user) }
  let(:clp_balance)  { create(:balance, :clp,  user: user, amount: BigDecimal("10_000_000")) }
  let(:btc_balance)  { create(:balance, :btc,  user: user, amount: BigDecimal("0")) }
  let(:locked_rate)  { BigDecimal("62_500_000") }
  let(:exchange) do
    create(:exchange,
           user: user,
           from_currency: "clp",
           to_currency: "btc",
           from_amount: BigDecimal("6_250_000"),
           locked_rate: locked_rate)
  end

  before { clp_balance; btc_balance }

  def call_service
    ExchangeExecutionService.new(exchange: exchange).call
  end

  describe "fiat → crypto (clp → btc)" do
    it "debits CLP balance" do
      call_service
      expect(clp_balance.reload.amount).to eq(BigDecimal("3_750_000"))
    end

    it "credits BTC balance" do
      call_service
      btc = btc_balance.reload.amount
      expect(btc.round(8)).to eq(BigDecimal("0.1"))
    end

    it "marks exchange as completed" do
      call_service
      expect(exchange.reload).to be_completed
    end

    it "sets executed_at" do
      call_service
      expect(exchange.reload.executed_at).to be_present
    end

    it "uses locked_rate, not current market rate" do
      call_service
      expected = (BigDecimal("6_250_000") / locked_rate).round(8)
      expect(exchange.reload.to_amount.round(8)).to eq(expected)
    end

    it "is atomic — CLP is not debited if BTC credit raises" do
      call_count = 0
      allow_any_instance_of(Balance).to receive(:update!).and_wrap_original do |m, *args|
        call_count += 1
        raise ActiveRecord::StatementInvalid, "forced failure" if call_count == 2
        m.call(*args)
      end
      expect { call_service }.to raise_error(ActiveRecord::StatementInvalid)
      expect(clp_balance.reload.amount).to eq(BigDecimal("10_000_000"))
    end
  end

  describe "crypto → fiat (btc → clp)" do
    let(:btc_balance)  { create(:balance, :btc, user: user, amount: BigDecimal("1")) }
    let(:clp_balance)  { create(:balance, :clp, user: user, amount: BigDecimal("0")) }
    let(:exchange) do
      create(:exchange,
             user: user,
             from_currency: "btc",
             to_currency: "clp",
             from_amount: BigDecimal("0.5"),
             locked_rate: BigDecimal("62_500_000"))
    end

    it "debits BTC and credits CLP" do
      call_service
      expect(btc_balance.reload.amount.round(8)).to eq(BigDecimal("0.5"))
      expect(clp_balance.reload.amount).to eq(BigDecimal("31_250_000"))
    end
  end

  describe "insufficient balance at execution" do
    before { clp_balance.update!(amount: BigDecimal("0")) }

    it "marks exchange as rejected" do
      call_service
      expect(exchange.reload).to be_rejected
      expect(exchange.failure_reason).to include("Insufficient")
    end

    it "does not modify balances" do
      call_service
      expect(clp_balance.reload.amount).to eq(BigDecimal("0"))
    end
  end
end
