module Api
  module V1
    class PricesController < ApplicationController
      def index
        result = PriceQuoteService.fetch
        render json: result
      rescue PriceQuoteService::PriceUnavailableError => e
        render_error(:service_unavailable, "Price data unavailable", "PRICE_UNAVAILABLE")
      end
    end
  end
end
