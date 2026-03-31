# Seed demo user with all balances
user = User.find_or_create_by!(email: "demo@vitawallet.io") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "Demo user token: #{user.api_token}"

balances = {
  "usd"  => BigDecimal("50"),
  "clp"  => BigDecimal("900000"),
  "btc"  => BigDecimal("0.05"),
  "usdc" => BigDecimal("100"),
  "usdt" => BigDecimal("0")
}

balances.each do |currency, amount|
  Balance.find_or_create_by!(user: user, currency: currency) do |b|
    b.amount = amount
  end
end

puts "Seeded user: #{user.email} with balances: #{balances.keys.join(', ')}"

# Seed example exchanges with different statuses
example_exchanges = [
  {
    from_currency: "clp",
    to_currency:   "btc",
    from_amount:   BigDecimal("500_000"),
    to_amount:     BigDecimal("0.00833333"),
    locked_rate:   BigDecimal("60_000_000"),
    status:        "completed"
  },
  {
    from_currency: "usd",
    to_currency:   "usdt",
    from_amount:   BigDecimal("200"),
    to_amount:     BigDecimal("200"),
    locked_rate:   BigDecimal("1"),
    status:        "pending"
  },
  {
    from_currency: "clp",
    to_currency:   "usd",
    from_amount:   BigDecimal("1_000_000"),
    to_amount:     BigDecimal("0"),
    locked_rate:   BigDecimal("940"),
    status:        "rejected"
  }
]

example_exchanges.each do |attrs|
  # Only create if none with this status already exists for this user
  next if Exchange.exists?(user: user, status: attrs[:status])

  Exchange.create!(
    user:          user,
    from_currency: attrs[:from_currency],
    to_currency:   attrs[:to_currency],
    from_amount:   attrs[:from_amount],
    to_amount:     attrs[:to_amount],
    locked_rate:   attrs[:locked_rate],
    status:        attrs[:status]
  )
  puts "Created #{attrs[:status]} exchange: #{attrs[:from_currency].upcase} → #{attrs[:to_currency].upcase}"
end
