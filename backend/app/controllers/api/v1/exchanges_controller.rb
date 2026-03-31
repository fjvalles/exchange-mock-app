module Api
  module V1
    class ExchangesController < ApplicationController
      include Pagy::Backend

      def index
        scope = ExchangeQuery.new(current_user, status: params[:status]).call
        pagy, exchanges = pagy(scope, items: per_page)
        meta = pagy_metadata(pagy)
        render json: {
          exchanges: ExchangeSerializer.render_as_hash(exchanges),
          pagination: meta.slice(:count, :page, :items, :pages, :prev, :next, :from, :to)
        }
      end

      def show
        exchange = current_user.exchanges.find_by(id: params[:id])
        return render_error(:not_found, "Exchange not found", "NOT_FOUND") unless exchange

        render json: { exchange: ExchangeSerializer.render_as_hash(exchange) }
      end

      def create
        result = CreateExchangeService.new(
          user: current_user,
          from_currency: exchange_params[:from_currency],
          to_currency: exchange_params[:to_currency],
          from_amount: exchange_params[:from_amount],
          idempotency_key: request.headers["Idempotency-Key"]
        ).call

        if result.success?
          status = result.duplicate? ? :ok : :accepted
          render json: { exchange: ExchangeSerializer.render_as_hash(result.data) }, status: status
        else
          render_service_error(result)
        end
      end

      private

      def exchange_params
        params.require(:exchange).permit(:from_currency, :to_currency, :from_amount)
      end

      def per_page
        [params.fetch(:per_page, 20).to_i, 100].min.clamp(1, 100)
      end

      def render_service_error(result)
        status_map = {
          insufficient_balance: :unprocessable_entity,
          invalid_currency_pair: :unprocessable_entity,
          price_unavailable: :service_unavailable,
          duplicate_idempotency_key: :conflict
        }
        http_status = status_map[result.error_code] || :unprocessable_entity
        render_error(http_status, result.error_message, result.error_code.to_s.upcase)
      end
    end
  end
end
