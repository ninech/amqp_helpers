#!/usr/bin/env ruby

require 'pathname'
APP_ROOT = File.join(File.dirname(Pathname.new(__FILE__).realpath),'..')

$:.unshift File.join(APP_ROOT, 'lib')

require 'amqp_helpers/publisher'

config = {
  name: 'nba-scores-daemon',
  environment: 'production',
  connection_params: {
    user: 'guest',
    password: 'guest',
    host: 'localhost',
    port: 5672
  },
  queue_params: { durable: false },
  exchanges: {
   'nba.scores' => {
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
}

publisher = AMQPHelpers::Publisher.new(config)

publisher.publish('test', 'nba.scores', 'north.seattle')
