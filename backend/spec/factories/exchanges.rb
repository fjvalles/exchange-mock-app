FactoryBot.define do
  factory :exchange do
    association :user
    from_currency { "clp" }
    to_currency   { "btc" }
    from_amount   { BigDecimal("1000000") }
    locked_rate   { BigDecimal("60000000") }
    status        { "pending" }

    trait :completed do
      status    { "completed" }
      to_amount { BigDecimal("0.01666666") }
      executed_at { Time.current }
    end

    trait :rejected do
      status         { "rejected" }
      failure_reason { "Insufficient balance" }
    end

    trait :with_idempotency_key do
      idempotency_key { SecureRandom.uuid }
    end
  end
end
