require "mock_redis"

RSpec.configure do |config|
  config.before(:each) do
    mock = MockRedis.new
    stub_const("REDIS", mock)
    Stoplight::Light.default_data_store = Stoplight::DataStore::Memory.new
  end
end
