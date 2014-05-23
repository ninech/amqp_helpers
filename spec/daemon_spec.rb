require 'spec_helper'

require 'amqp_helpers/daemon'

describe AMQPHelpers::Daemon do
  describe '#start' do
    subject { described_class.new }

    it 'starts the AMQP loop with the given config' do
      AMQP.should_receive(:start).with instance_of(Hash)
      subject.start
    end

    let(:config) {
      {
        name: 'lala',
        queue_name: 'example-queue',
        queue_params: { durable: false },
        logger: Logger.new('/dev/null'),
        connection_params: { host: 'localhost', port: 1337 },
        exchanges: {
          'test-topic' => {
            params: { type: :topic, durable: false },
            bindings: [ { routing_key: 'lala.#' } ]
          }
        }
      }
    }
    let(:block) { @block }
    let(:connection) { double(AMQP) }
    let(:exchange) { Object.new }
    let(:queue) { double(AMQP::Queue) }

    subject { described_class.new(config) }

    before(:each) do
      AMQP.stub(:start) do |&block|
        @block = block
      end
      subject.start { |a, b| nil }
    end

    before(:each) do
      EM.stub(:reactor_running?).and_return(true)
      connection.stub(:auto_recovering?).and_return(true)
      connection.stub(:open?).and_return(true)
      connection.stub(:channel_max).and_return(0)
      connection.stub(:on_connection)
      connection.stub(:on_open)
      connection.stub(:on_recovery)
      connection.stub(:on_error)
      connection.stub(:on_tcp_connection_loss)
      connection.stub(:next_channel_id).and_return(0)
      AMQP::Channel.any_instance.stub(:topic).and_return(exchange)
      AMQP::Channel.any_instance.stub(:queue).and_return(queue)
      queue.stub(:bind)
      queue.stub(:subscribe)
    end

    it 'creates a non-durable queue' do
      AMQP::Channel.any_instance.should_receive(:queue).with('example-queue', durable: false).and_return(queue)
      block.call(connection)
    end

    it 'creates the topic' do
      AMQP::Channel.any_instance.should_receive(:topic).with('test-topic', type: :topic, durable: false).and_return(exchange)
      block.call(connection)
    end

    it 'binds the queue to the exchange' do
      queue.should_receive(:bind).with(exchange, routing_key: 'lala.#')
      block.call(connection)
    end

    it 'subscribes' do
      queue.should_receive(:subscribe)
      block.call(connection)
    end
  end
end
