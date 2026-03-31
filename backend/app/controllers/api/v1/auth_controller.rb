module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: [:login]

      def login
        user = User.find_by(email: params[:email]&.strip&.downcase)

        if user&.authenticate(params[:password])
          render json: {
            token: user.api_token,
            user: { id: user.id, email: user.email }
          }, status: :ok
        else
          render_error(:unauthorized, "Invalid email or password", "INVALID_CREDENTIALS")
        end
      end

      def logout
        render json: { message: "Logged out" }, status: :ok
      end
    end
  end
end
