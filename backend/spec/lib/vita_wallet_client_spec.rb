require "rails_helper"

RSpec.describe VitaWalletClient do
  let(:api_url) { "https://api.stage.vitawallet.io/api/prices_quote" }

  describe ".get_prices" do
    context "on success" do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: {
              prices: [
                { currency: "BTC", price_usd: "60000", price_clp: "55000000" },
                { currency: "USDC", price_usd: "1", price_clp: "960" },
                { currency: "USDT", price_usd: "1", price_clp: "958" }
              ]
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns parsed JSON body" do
        result = VitaWalletClient.get_prices
        expect(result).to be_a(Hash)
        expect(result[:prices]).to be_an(Array)
        expect(result[:prices].length).to eq(3)
      end
    end

    context "on server error" do
      before do
        stub_request(:get, api_url)
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "raises a ClientError" do
        expect { VitaWalletClient.get_prices }.to raise_error(VitaWalletClient::ClientError)
      end
    end

    context "on timeout" do
      before do
        stub_request(:get, api_url).to_timeout
      end

      it "raises a ClientError" do
        expect { VitaWalletClient.get_prices }.to raise_error(VitaWalletClient::ClientError)
      end
    end
  end
end
