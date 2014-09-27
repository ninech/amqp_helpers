#!/usr/bin/env ruby

require 'pathname'
APP_ROOT = File.join(File.dirname(Pathname.new(__FILE__).realpath),'..')

$:.unshift File.join(APP_ROOT, 'lib')

require 'amqp_helpers/daemon'

AMQPHelpers::Daemon.new({
  name: 'nba-scores-daemon',
  environment: 'development',
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
}).start do |delivery_info, payload|
  puts "AMQP Incoming message #{payload}"
end
