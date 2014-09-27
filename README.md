# amqp_helpers [![Build Status](https://travis-ci.org/ninech/amqp_helpers.svg)](https://travis-ci.org/ninech/amqp_helpers)

Simple utilities to achieve various AMQP tasks.

## Daemon

`AMQPHelpers::Daemon` allows you to build a simple message consumer.

### Example

``` ruby
AMQPHelpers::Daemon.new({
  name: 'nba-scores-daemon',
  environment: 'production',
  logger: PXEConfGen.logger,
  connection_params: {
    host: 'localhost',
    port: 5672
  },
  queue_params: { durable: false },
  exchanges: {
   'nba.scores': {
      params: {
        type: :topic,
        durable: false
      },
      bindings: [
        { routing_key: 'north.#' },
        { routing_key: 'south.#' }
      ]
    }
  }
}).start do |delivery_info, payload|
  puts "AMQP Incoming message #{payload}"
end
```

## Publisher

`AMQPHelpers::Publisher` allows you to publish an AMQP message in an easy way.

### Example

It takes the same configuration hash as the daemon does. The second argument specifies
which exchange configuration should be used. The third argument is the routing key.

```ruby
publisher = AMQPHelpers::Publisher.new({
  name: 'nba-scores-daemon',
  environment: 'production',
  logger: PXEConfGen.logger,
  connection_params: {
    host: 'localhost',
    port: 5672
  },
  queue_params: { durable: false },
  exchanges: {
   'nba.scores': {
      params: {
        type: :topic,
        durable: false
      },
      bindings: [
        { routing_key: 'north.#' },
        { routing_key: 'south.#' }
      ]
    }
  })

publisher.publish('1:1', 'nba.scores', 'south.east') # => true
```
