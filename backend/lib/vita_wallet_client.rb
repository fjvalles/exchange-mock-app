require "faraday"
require "faraday/retry"

class VitaWalletClient
  API_URL = "https://api.stage.vitawallet.io/api/prices_quote".freeze

  ClientError = Class.new(StandardError)

  def self.get_prices
    response = connection.get(API_URL)

    unless response.success?
      raise ClientError, "VitaWallet API returned #{response.status}"
    end

    response.body
  rescue Faraday::Error => e
    raise ClientError, "VitaWallet API connection failed: #{e.message}"
  end

  private_class_method def self.connection
    @connection ||= Faraday.new do |f|
      f.options.timeout      = 5
      f.options.open_timeout = 3
      f.request :retry, max: 2, interval: 0.5, retry_statuses: [500, 502, 503, 504]
      f.response :json, parser_options: { symbolize_names: true }
      f.adapter Faraday.default_adapter
    end
  end
end
