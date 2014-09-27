require 'bunny'
require 'json'

module AMQPHelpers
  class Publisher

    def initialize(config)
      @config = config
    end

    def publish(message, exchange_name, routing_key)
      Bunny.run(@config) do |connection|
        exchange_config = @config[:exchanges][exchange_name]
        return false unless exchange_config

        exchange = connection.exchange(exchange_name, exchange_config[:params])
        exchange.publish(message.to_json,
                         key: routing_key,
                         persistent: exchange_config[:params][:durable],
                         content_type: 'application/json')
      end
      true
    rescue => error
      Airbrake.notify_or_ignore(error) if defined?(Airbrake)
      Rails.logger.error("#{error.class}: #{error}") if defined?(Rails)
      raise error
    end
  end
end
