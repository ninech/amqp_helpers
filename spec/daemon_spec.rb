require 'spec_helper'

require 'amqp_helpers/daemon'

describe AMQPHelpers::Daemon do
  describe '#start' do
    subject { described_class.new }

    it 'starts the AMQP loop with the given config' do
      expect(AMQP).to receive(:start).with instance_of(Hash)
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
            bindings: [{ routing_key: 'lala.#' }]
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
      allow(AMQP).to receive(:start) do |&block|
        @block = block
      end
      subject.start { |a, b| nil }
    end

    before(:each) do
      allow(EM).to receive(:reactor_running?).and_return(true)
      allow(connection).to receive(:auto_recovering?).and_return(true)
      allow(connection).to receive(:open?).and_return(true)
      allow(connection).to receive(:channel_max).and_return(0)
      allow(connection).to receive(:on_connection)
      allow(connection).to receive(:on_open)
      allow(connection).to receive(:on_recovery)
      allow(connection).to receive(:on_error)
      allow(connection).to receive(:on_tcp_connection_loss)
      allow(connection).to receive(:next_channel_id).and_return(0)
      allow_any_instance_of(AMQP::Channel).to receive(:topic).and_return(exchange)
      allow_any_instance_of(AMQP::Channel).to receive(:queue).and_return(queue)
      allow(queue).to receive(:bind)
      allow(queue).to receive(:subscribe)
    end

    it 'creates a non-durable queue' do
      expect_any_instance_of(AMQP::Channel).to receive(:queue).with('example-queue', durable: false).and_return(queue)
      block.call(connection)
    end

    it 'creates the topic' do
      expect_any_instance_of(AMQP::Channel).to receive(:topic).with('test-topic', type: :topic, durable: false).and_return(exchange)
      block.call(connection)
    end

    it 'binds the queue to the exchange' do
      expect(queue).to receive(:bind).with(exchange, routing_key: 'lala.#')
      block.call(connection)
    end

    it 'subscribes' do
      expect(queue).to receive(:subscribe)
      block.call(connection)
    end

    it 'enables you to use options (e.g. ack: true) for the subscribing process' do
      subject.start(ack: true)
      expect(queue).to receive(:subscribe).with(ack: true)
      block.call(connection)
    end
  end
end
