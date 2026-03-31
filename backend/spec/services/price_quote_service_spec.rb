require "rails_helper"

RSpec.describe PriceQuoteService do
  let(:api_url) { "https://api.stage.vitawallet.io/api/prices_quote" }

  # VitaWallet API returns crypto-per-CLP rates keyed by currency symbol
  let(:mock_api_response) do
    {
      btc:  { clp_buy: "0.0000000166666", clp_sell: "0.0000000181818" },
      usdc: { clp_buy: "0.0010416666",    clp_sell: "0.0010869565" },
      usdt: { clp_buy: "0.0010416666",    clp_sell: "0.0010869565" },
      valid_until: "2026-03-31T12:00:00Z"
    }
  end

  describe ".fetch" do
    context "when the external API is available" do
      before do
        stub_request(:get, api_url)
          .to_return(status: 200, body: mock_api_response.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "returns structured price data" do
        result = PriceQuoteService.fetch
        expect(result[:prices]).to be_an(Array)
        expect(result[:prices].map { |p| p[:base] }).to contain_exactly("btc", "usdc", "usdt")
      end

      it "includes BigDecimal buy and sell rates as CLP-per-crypto" do
        result = PriceQuoteService.fetch
        btc = result[:prices].find { |p| p[:base] == "btc" }
        expect(btc[:buy_rate]).to  be_a(BigDecimal)
        expect(btc[:sell_rate]).to be_a(BigDecimal)
        # Both rates should be large CLP values (tens of millions for BTC)
        expect(btc[:buy_rate]).to  be > 1_000_000
        expect(btc[:sell_rate]).to be > 1_000_000
      end

      it "buy_rate is approximately 1/clp_sell (CLP per 1 BTC)" do
        result = PriceQuoteService.fetch
        btc = result[:prices].find { |p| p[:base] == "btc" }
        # 1 / 0.0000000181818 ≈ 55_000_036 CLP
        expect(btc[:buy_rate]).to be_within(BigDecimal("1000")).of(BigDecimal("55000000"))
      end

      it "caches the result in Redis" do
        PriceQuoteService.fetch
        cached = REDIS.get(PriceQuoteService::CACHE_KEY)
        expect(cached).to be_present
      end

      it "persists an audit record to the DB" do
        expect { PriceQuoteService.fetch }.to change(PriceQuote, :count).by(3)
      end

      it "marks response as not cached on fresh fetch" do
        result = PriceQuoteService.fetch
        expect(result[:cached]).to be(false)
      end
    end

    context "when API returns malformed data for one currency" do
      let(:bad_response) do
        mock_api_response.merge(btc: { clp_buy: "", clp_sell: "" })
      end

      before do
        stub_request(:get, api_url)
          .to_return(status: 200, body: bad_response.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "skips the malformed currency and returns the rest" do
        result = PriceQuoteService.fetch
        expect(result[:prices].map { |p| p[:base] }).to contain_exactly("usdc", "usdt")
      end
    end

    context "when API returns all malformed data" do
      let(:all_bad_response) do
        { btc: { clp_buy: "", clp_sell: "" },
          usdc: { clp_buy: "", clp_sell: "" },
          usdt: { clp_buy: "", clp_sell: "" } }
      end

      before do
        stub_request(:get, api_url)
          .to_return(status: 200, body: all_bad_response.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it "raises PriceUnavailableError" do
        # When all prices are empty the parse_response raises PriceUnavailableError,
        # which triggers the Stoplight fallback that tries the cache (cold => raises again)
        expect { PriceQuoteService.fetch }.to raise_error(PriceQuoteService::PriceUnavailableError)
      end
    end

    context "when the external API is down (500)" do
      before do
        stub_request(:get, api_url).to_return(status: 500)
      end

      it "raises PriceUnavailableError when cache is cold" do
        expect { PriceQuoteService.fetch }.to raise_error(PriceQuoteService::PriceUnavailableError)
      end

      context "with cached data" do
        before do
          # Prime the cache with a successful response first
          stub_request(:get, api_url)
            .to_return(status: 200, body: mock_api_response.to_json,
                       headers: { "Content-Type" => "application/json" })
          PriceQuoteService.fetch # populate cache

          # Now make the API return 500
          stub_request(:get, api_url).to_return(status: 500)
        end

        it "returns cached data" do
          result = PriceQuoteService.fetch
          expect(result[:cached]).to be(true)
          expect(result[:prices]).to be_present
        end

        it "cached prices have correct base/quote structure" do
          result = PriceQuoteService.fetch
          result[:prices].each do |p|
            expect(p[:base]).to  be_in(%w[btc usdc usdt])
            expect(p[:quote]).to eq("clp")
          end
        end
      end
    end

    context "when the external API is unreachable (connection error)" do
      before do
        stub_request(:get, api_url).to_raise(Faraday::ConnectionFailed.new("connection refused"))
      end

      it "raises PriceUnavailableError when cache is cold" do
        expect { PriceQuoteService.fetch }.to raise_error(PriceQuoteService::PriceUnavailableError)
      end
    end
  end
end
