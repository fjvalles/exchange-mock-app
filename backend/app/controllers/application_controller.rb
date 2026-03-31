class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_user = User.find_by_token(token)
    render_error(:unauthorized, "Invalid or missing token", "UNAUTHORIZED") unless @current_user
  end

  def current_user
    @current_user
  end

  def render_error(status, message, code, details = {})
    render json: { error: message, code: code, details: details }.compact_blank,
           status: status
  end
end
