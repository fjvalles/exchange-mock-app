require "rails_helper"

RSpec.describe CreateExchangeService do
  let(:user)        { create(:user) }
  let(:clp_balance) { create(:balance, :clp, user: user, amount: BigDecimal("10_000_000")) }
  let(:btc_balance) { create(:balance, :btc, user: user, amount: BigDecimal("0")) }
  let(:usd_balance) { create(:balance, :usd, user: user, amount: BigDecimal("500")) }
  let(:mock_price)  { BigDecimal("60_000_000") }

  before do
    clp_balance
    btc_balance
    usd_balance
    allow(PriceQuoteService).to receive(:fetch).and_return({
      prices: [{ base: "btc", quote: "clp", buy_rate: mock_price, sell_rate: mock_price * BigDecimal("0.99") }]
    })
    allow(ExchangeExecutionJob).to receive(:perform_later)
  end

  def call_service(**overrides)
    CreateExchangeService.new(
      user: user,
      from_currency: "clp",
      to_currency:   "btc",
      from_amount:   "1000000",
      **overrides
    ).call
  end

  describe "successful exchange creation" do
    it "returns success" do
      result = call_service
      expect(result).to be_success
    end

    it "creates an exchange record with pending status" do
      expect { call_service }.to change(Exchange, :count).by(1)
      exchange = Exchange.last
      expect(exchange.status).to eq("pending")
      expect(exchange.from_currency).to eq("clp")
      expect(exchange.to_currency).to   eq("btc")
    end

    it "stores the locked rate at creation time" do
      call_service
      expect(Exchange.last.locked_rate).to eq(mock_price)
    end

    it "enqueues ExchangeExecutionJob" do
      call_service
      expect(ExchangeExecutionJob).to have_received(:perform_later).with(Integer)
    end

    it "does NOT debit balance at creation (deferred to job)" do
      call_service
      expect(clp_balance.reload.amount).to eq(BigDecimal("10_000_000"))
    end
  end

  describe "cross-rate pairs (clp <-> usd via mock rates)" do
    before do
      allow(PriceQuoteService).to receive(:fetch).and_return({
        prices: [{ base: "btc", quote: "clp", buy_rate: BigDecimal("60_000_000"), sell_rate: BigDecimal("59_400_000") }]
      })
    end

    it "accepts clp -> usd as a valid pair" do
      result = call_service(from_currency: "clp", to_currency: "usd")
      expect(result).to be_success
      expect(Exchange.last.from_currency).to eq("clp")
      expect(Exchange.last.to_currency).to   eq("usd")
    end

    it "accepts usd -> clp as a valid pair" do
      result = call_service(from_currency: "usd", to_currency: "clp", from_amount: "100")
      expect(result).to be_success
    end

    it "stores a positive non-nil locked_rate for clp -> usd" do
      call_service(from_currency: "clp", to_currency: "usd")
      expect(Exchange.last.locked_rate).to be > 0
    end
  end

  describe "validation failures" do
    it "returns failure for insufficient balance" do
      result = call_service(from_amount: "99_000_000")
      expect(result).to be_failure
      expect(result.error_code).to eq(:insufficient_balance)
    end

    it "returns failure for invalid currency pair (btc -> usdt)" do
      result = call_service(from_currency: "btc", to_currency: "usdt")
      expect(result).to be_failure
      expect(result.error_code).to eq(:invalid_currency_pair)
    end

    it "returns failure when price is unavailable" do
      allow(PriceQuoteService).to receive(:fetch).and_raise(PriceQuoteService::PriceUnavailableError)
      result = call_service
      expect(result).to be_failure
      expect(result.error_code).to eq(:price_unavailable)
    end

    it "returns failure when price data yields nil for the requested pair" do
      allow(PriceQuoteService).to receive(:fetch).and_return({ prices: [] })
      result = call_service
      expect(result).to be_failure
      expect(result.error_code).to eq(:price_unavailable)
    end
  end

  describe "idempotency" do
    let(:idem_key) { SecureRandom.uuid }

    it "returns the original exchange on duplicate key" do
      first_result  = call_service(idempotency_key: idem_key)
      second_result = call_service(idempotency_key: idem_key)

      expect(Exchange.count).to eq(1)
      expect(second_result.data.id).to eq(first_result.data.id)
      expect(second_result).to be_duplicate
    end

    it "enqueues job only once for duplicate key" do
      call_service(idempotency_key: idem_key)
      call_service(idempotency_key: idem_key)
      expect(ExchangeExecutionJob).to have_received(:perform_later).once
    end
  end
end
