# Seed demo user with all balances
user = User.find_or_create_by!(email: "demo@vitawallet.io") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "Demo user token: #{user.api_token}"

balances = {
  "usd"  => BigDecimal("5000"),
  "clp"  => BigDecimal("4_500_000"),
  "btc"  => BigDecimal("0.05"),
  "usdc" => BigDecimal("1000"),
  "usdt" => BigDecimal("500")
}

balances.each do |currency, amount|
  Balance.find_or_create_by!(user: user, currency: currency) do |b|
    b.amount = amount
  end
end

puts "Seeded user: #{user.email} with balances: #{balances.keys.join(', ')}"
