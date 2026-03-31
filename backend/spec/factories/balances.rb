FactoryBot.define do
  factory :balance do
    association :user
    currency { "clp" }
    amount   { BigDecimal("1000000") }

    trait :usd   do currency { "usd" };  amount { BigDecimal("500") } end
    trait :clp   do currency { "clp" };  amount { BigDecimal("500000") } end
    trait :btc   do currency { "btc" };  amount { BigDecimal("0.1") } end
    trait :usdc  do currency { "usdc" }; amount { BigDecimal("200") } end
    trait :usdt  do currency { "usdt" }; amount { BigDecimal("200") } end
    trait :empty do amount { BigDecimal("0") } end
  end
end
