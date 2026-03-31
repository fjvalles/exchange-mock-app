Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))

# Throttle all API requests by IP
Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |request|
  request.ip if request.path.start_with?("/api/")
end

# Throttle per token (authenticated requests)
Rack::Attack.throttle("api/token", limit: 60, period: 1.minute) do |request|
  token = request.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
  token if token.present? && request.path.start_with?("/api/")
end

# Strict throttle on login endpoint
Rack::Attack.throttle("login/ip", limit: 5, period: 1.minute) do |request|
  request.ip if request.path == "/api/v1/auth/login" && request.post?
end

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"] || {})[:period]
  [
    429,
    { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
    [{ error: "Too many requests", code: "RATE_LIMIT_EXCEEDED" }.to_json]
  ]
end
