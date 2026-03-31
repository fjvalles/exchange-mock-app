module Api
  module V1
    class BalancesController < ApplicationController
      def index
        balances = current_user.balances.order(:currency)
        render json: { balances: BalanceSerializer.render_as_hash(balances) }
      end
    end
  end
end
