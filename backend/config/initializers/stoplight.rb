require "stoplight"

redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
Stoplight::Light.default_data_store = Stoplight::DataStore::Redis.new(redis)
