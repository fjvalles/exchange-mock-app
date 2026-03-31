require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      it "returns 200 with token and user info" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "password123" }

        expect(response).to have_http_status(:ok)
        expect(json_response[:token]).to eq(user.api_token)
        expect(json_response[:user][:email]).to eq("test@example.com")
      end

      it "is case-insensitive for email" do
        post "/api/v1/auth/login", params: { email: "TEST@EXAMPLE.COM", password: "password123" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid credentials" do
      it "returns 401 for wrong password" do
        post "/api/v1/auth/login", params: { email: "test@example.com", password: "wrong" }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:code]).to eq("INVALID_CREDENTIALS")
      end

      it "returns 401 for unknown email" do
        post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "password123" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "protected endpoints" do
    it "returns 401 without token" do
      get "/api/v1/balances"
      expect(response).to have_http_status(:unauthorized)
      expect(json_response[:code]).to eq("UNAUTHORIZED")
    end

    it "returns 401 with invalid token" do
      get "/api/v1/balances", headers: { "Authorization" => "Bearer invalid_token" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "grants access with valid token" do
      user = create(:user)
      get "/api/v1/balances", headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
    end
  end
end
