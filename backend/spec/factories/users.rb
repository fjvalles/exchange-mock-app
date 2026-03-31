FactoryBot.define do
  factory :user do
    email    { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_balances do
      after(:create) do |user|
        Balance::CURRENCIES.each do |currency|
          create(:balance, user: user, currency: currency)
        end
      end
    end
  end
end
