require "rails_helper"

RSpec.describe "Api::V1::Exchanges", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:mock_prices) do
    {
      prices: [{ base: "btc", quote: "clp", buy_rate: BigDecimal("60_000_000"), sell_rate: BigDecimal("59_400_000") }]
    }
  end

  before do
    create(:balance, :clp, user: user, amount: BigDecimal("5_000_000"))
    create(:balance, :btc, user: user, amount: BigDecimal("0"))
    allow(PriceQuoteService).to receive(:fetch).and_return(mock_prices)
    allow(ExchangeExecutionJob).to receive(:perform_later)
  end

  describe "POST /api/v1/exchanges" do
    let(:valid_params) { { exchange: { from_currency: "clp", to_currency: "btc", from_amount: "1000000" } } }

    it "returns 202 Accepted with pending exchange" do
      post "/api/v1/exchanges", params: valid_params, headers: headers
      expect(response).to have_http_status(:accepted)
      expect(json_response[:exchange][:status]).to eq("pending")
      expect(json_response[:exchange][:from_currency]).to eq("clp")
    end

    it "enqueues the execution job" do
      post "/api/v1/exchanges", params: valid_params, headers: headers
      expect(ExchangeExecutionJob).to have_received(:perform_later).with(Integer)
    end

    it "returns 422 for insufficient balance" do
      post "/api/v1/exchanges",
           params: { exchange: { from_currency: "clp", to_currency: "btc", from_amount: "99_000_000" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:code]).to eq("INSUFFICIENT_BALANCE")
    end

    it "returns 422 for invalid currency pair" do
      post "/api/v1/exchanges",
           params: { exchange: { from_currency: "btc", to_currency: "usdt", from_amount: "1" } },
           headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:code]).to eq("INVALID_CURRENCY_PAIR")
    end

    it "returns 503 when price is unavailable" do
      allow(PriceQuoteService).to receive(:fetch).and_raise(PriceQuoteService::PriceUnavailableError)
      post "/api/v1/exchanges", params: valid_params, headers: headers
      expect(response).to have_http_status(:service_unavailable)
    end

    context "with idempotency key" do
      let(:idem_key) { SecureRandom.uuid }

      it "returns 200 (not 202) on duplicate" do
        post "/api/v1/exchanges", params: valid_params, headers: headers.merge("Idempotency-Key" => idem_key)
        post "/api/v1/exchanges", params: valid_params, headers: headers.merge("Idempotency-Key" => idem_key)

        expect(response).to have_http_status(:ok)
        expect(Exchange.count).to eq(1)
      end
    end

    it "returns 401 without token" do
      post "/api/v1/exchanges", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/exchanges" do
    before do
      create_list(:exchange, 3, :completed, user: user)
      create(:exchange, :rejected, user: user)
      create(:exchange, user: user) # pending
    end

    it "returns paginated exchange list" do
      get "/api/v1/exchanges", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response[:exchanges].length).to eq(5)
      expect(json_response[:pagination][:count]).to eq(5)
    end

    it "filters by status" do
      get "/api/v1/exchanges", params: { status: "completed" }, headers: headers
      statuses = json_response[:exchanges].map { |e| e[:status] }
      expect(statuses).to all(eq("completed"))
      expect(json_response[:exchanges].length).to eq(3)
    end

    it "does not return other users' exchanges" do
      other_user = create(:user)
      create(:exchange, user: other_user)
      get "/api/v1/exchanges", headers: headers
      expect(json_response[:exchanges].length).to eq(5)
    end
  end

  describe "GET /api/v1/exchanges/:id" do
    let!(:exchange) { create(:exchange, user: user) }

    it "returns the exchange" do
      get "/api/v1/exchanges/#{exchange.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response[:exchange][:id]).to eq(exchange.id)
    end

    it "returns 404 for another user's exchange" do
      other = create(:exchange, user: create(:user))
      get "/api/v1/exchanges/#{other.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
