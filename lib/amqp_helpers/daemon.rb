require 'amqp'
require 'logger'
require 'socket'
require 'syslogger'

module AMQPHelpers
  class Daemon

    class Error < StandardError; end
    class ConnectionError < Error; end
    class ChannelError < Error; end

    DEFAULT_RECONNECT_WAIT_TIME = 10

    attr_accessor :name, :exchanges, :connection_params
    attr_writer :environment, :logger, :queue_name, :queue_params, :reconnect_wait_time

    def initialize(config)
      config.each do |key, value|
        setter = "#{key}="
        if respond_to?(setter)
          send(setter, value)
        end
      end
    end

    def start(&handler)
      logger.info "Starting #{name} daemon..."
      tcp_connection_failure_handler = Proc.new(&method(:handle_tcp_connection_failure))
      amqp_params = { on_tcp_connection_failure: tcp_connection_failure_handler}.merge(connection_params)
      AMQP.start(amqp_params) do |connection|
        connection.on_error(&method(:handle_connection_error))
        channel = initialize_channel(connection)
        connection.on_tcp_connection_loss(&method(:handle_tcp_connection_loss))
        connection.on_recovery(&method(:handle_recovery))

        queue = initialize_queue(channel)
        queue.subscribe(&handler)

        show_stopper = Proc.new do
          logger.info "Signal INT received. #{name} is going down... I REPEAT: WE ARE GOING DOWN!"
          connection.close { EventMachine.stop }
        end
        Signal.trap 'INT', show_stopper
      end
    end

    def environment
      @environment ||= 'development'
    end

    def queue_params
      @queue_params ||= {}
    end

    def queue_name
      @queue_name ||= "#{Socket.gethostname}.#{name}"
    end

    def logger
      @logger ||= if environment == 'development'
                    Logger.new(STDOUT)
                  else
                    Syslogger.new(name, Syslog::LOG_PID, Syslog::LOG_LOCAL0)
                  end
    end

    def reconnect_wait_time
      @reconnect_wait_time ||= DEFAULT_RECONNECT_WAIT_TIME
    end

    protected
    def handle_tcp_connection_failure(settings)
      logger.error "[network failure] Could not connect to #{settings[:host]}:#{settings[:port]}"
      raise ConnectionError, "Failed to connect!"
    end

    def handle_connection_error(connection, connection_close)
      logger.error "[connection.close] Reply code = #{connection_close.reply_code}, reply text = #{connection_close.reply_text}"
      # check if graceful broker shutdown
      if connection_close.reply_code == 320
        logger.info "[connection.close] Setting up a periodic reconnection timer (#{reconnect_wait_time}s)..."
        connection.periodically_reconnect(reconnect_wait_time)
      else
        raise ConnectionError, connection_close.reply_text
      end
    end

    def handle_channel_error(channel, channel_close)
      logger.error "[channel.close] Reply code = #{channel_close.reply_code}, reply text = #{channel_close.reply_text}"
      raise ChannelError, channel_close.reply_text
    end

    def handle_tcp_connection_loss(connection, settings)
      logger.error '[network failure] Trying to reconnect...'
      connection.reconnect(false, reconnect_wait_time)
    end

    def handle_recovery(connection, settings)
      logger.info 'Yay, reconnected! All systems go!'
    end

    def initialize_channel(connection)
      channel = AMQP::Channel.new(connection)
      channel.auto_recovery = true
      channel.on_error(&method(:handle_channel_error))
    end

    def initialize_queue(channel)
      channel.queue(queue_name, queue_params).tap do |queue|
        exchanges.each do |exchange_name, exchange_config|
          exchange = channel.topic(exchange_name, exchange_config[:params])
          (exchange_config[:bindings] || []).each do |params|
            queue.bind(exchange, params)
          end
        end
      end
    end

  end
end
