class ExchangeExecutionJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 5

  def perform(exchange_id)
    exchange = Exchange.find(exchange_id)
    return if exchange.completed? || exchange.rejected?

    ExchangeExecutionService.new(exchange: exchange).call
  rescue ActiveRecord::StaleObjectError
    raise  # Sidekiq will retry
  rescue ActiveRecord::RecordNotFound
    # Exchange was deleted — nothing to do
  end
end
