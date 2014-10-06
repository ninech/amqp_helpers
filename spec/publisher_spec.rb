require 'spec_helper'

require 'amqp_helpers/publisher'

describe AMQPHelpers::Publisher do
  let(:config) do
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
  end

  let(:instance) { described_class.new(config) }
  let(:bunny_double) { double(Bunny::Session) }
  let(:exchange_double) { double(Bunny::Exchange) }

  before do
    allow(Bunny).to receive(:run).and_yield(bunny_double)
    allow(bunny_double).to receive(:exchange).and_return(exchange_double)
  end

  describe '#publish' do
    context 'exchange specified' do
      it 'publishes the message' do
        expect(exchange_double).to receive(:publish).
          with('we are testing', key: 'lala.will.exist', persistent: false, content_type: 'application/json')

        expect(instance.publish('we are testing', 'test-topic', 'lala.will.exist')).to eq(true)
      end
    end

    context 'wrong exchange specified' do
      it 'does not publish the message' do
        expect(exchange_double).to_not receive(:publish)
        expect(instance.publish('we are testing', 'undefined-topic', 'lala.will.exist')).to eq(false)
      end
    end
  end
end
