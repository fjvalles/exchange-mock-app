require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:balances).dependent(:destroy) }
    it { is_expected.to have_many(:exchanges).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it "enforces unique emails (case insensitive)" do
      create(:user, email: "taken@example.com")
      duplicate = build(:user, email: "TAKEN@EXAMPLE.COM")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end
    it { is_expected.to have_secure_password }

    it "rejects invalid email format" do
      user.email = "not-an-email"
      expect(user).not_to be_valid
    end
  end

  describe "api_token" do
    it "generates a token before create" do
      user = create(:user)
      expect(user.api_token).to be_present
      expect(user.api_token.length).to eq(64)
    end

    it "generates unique tokens" do
      tokens = create_list(:user, 3).map(&:api_token)
      expect(tokens.uniq.length).to eq(3)
    end

    it "is findable by token" do
      user = create(:user)
      expect(User.find_by_token(user.api_token)).to eq(user)
    end
  end

  describe "email normalization" do
    it "lowercases and strips email before validation" do
      user = create(:user, email: "  TEST@EXAMPLE.COM  ")
      expect(user.email).to eq("test@example.com")
    end
  end
end
