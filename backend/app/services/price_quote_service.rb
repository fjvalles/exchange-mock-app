class PriceQuoteService
  CACHE_KEY = "price_quote:latest".freeze
  CACHE_TTL  = 60 # seconds

  PriceUnavailableError = Class.new(StandardError)

  def self.fetch
    Stoplight("vita_wallet_prices") do
      response = VitaWalletClient.get_prices
      parsed   = parse_response(response)
      cache_prices(parsed)
      persist_to_db(parsed)
      build_result(parsed, cached: false)
    end
      .with_fallback { |_error| read_from_cache! }
      .with_cool_off_time(30)
      .with_threshold(3)
      .run
  rescue Stoplight::Error::RedLight
    read_from_cache!
  end

  private_class_method def self.parse_response(response)
    currencies = [:btc, :usdc, :usdt]

    prices = currencies.filter_map do |curr|
      price_data = response[curr]
      next unless price_data

      clp_sell_str = price_data[:clp_sell].to_s.strip
      clp_buy_str  = price_data[:clp_buy].to_s.strip
      next if clp_sell_str.empty? || clp_buy_str.empty?

      clp_sell_rate = BigDecimal(clp_sell_str)
      clp_buy_rate  = BigDecimal(clp_buy_str)
      next if clp_sell_rate.zero? || clp_buy_rate.zero?

      # API returns crypto amount per 1 CLP.
      # So `1 BTC = 1.0 / clp_sell` CLP
      # Selling CLP to buy Crypto => user "buys" crypto => `1.0 / clp_sell`
      # Buying CLP with Crypto => user "sells" crypto => `1.0 / clp_buy`
      buy_clp  = (BigDecimal("1.0") / clp_sell_rate).round(8)
      sell_clp = (BigDecimal("1.0") / clp_buy_rate).round(8)

      {
        base:      curr.to_s,
        quote:     "clp",
        buy_rate:  buy_clp,
        sell_rate: sell_clp
      }
    rescue ArgumentError, TypeError => e
      Rails.logger.warn("[PriceQuoteService] Skipping #{curr} due to bad data: #{e.message}")
      nil
    end

    raise PriceUnavailableError, "API returned no usable price data" if prices.empty?

    { prices: prices, fetched_at: Time.current }
  end

  private_class_method def self.cache_prices(parsed)
    serializable = parsed.merge(
      prices: parsed[:prices].map { |p| p.merge(buy_rate: p[:buy_rate].to_s, sell_rate: p[:sell_rate].to_s) },
      fetched_at: parsed[:fetched_at].iso8601
    )
    REDIS.setex(CACHE_KEY, CACHE_TTL, serializable.to_json)
  end

  private_class_method def self.persist_to_db(parsed)
    now = parsed[:fetched_at]
    parsed[:prices].each do |price|
      PriceQuote.create!(
        base:       price[:base],
        quote:      price[:quote],
        buy_rate:   price[:buy_rate],
        sell_rate:  price[:sell_rate],
        fetched_at: now
      )
    end
  rescue ActiveRecord::RecordInvalid
    # Non-critical — audit trail only, don't fail the request
  end

  private_class_method def self.read_from_cache!
    raw = REDIS.get(CACHE_KEY)
    raise PriceUnavailableError, "No price data available" if raw.nil?

    data = JSON.parse(raw, symbolize_names: true)
    prices = data[:prices].map do |p|
      p.merge(buy_rate: BigDecimal(p[:buy_rate]), sell_rate: BigDecimal(p[:sell_rate]))
    end
    build_result({ prices: prices, fetched_at: data[:fetched_at] }, cached: true)
  end

  private_class_method def self.build_result(parsed, cached:)
    {
      prices:     parsed[:prices],
      cached:     cached,
      fetched_at: parsed[:fetched_at]
    }
  end
end
