#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler'
require 'rubygems'
require 'amqp'
require 'json'
require 'mongo'

require File.join(File.dirname(__FILE__), 'agent')

module Ares
	class Master < Agent
		def initialize
			@mongo_conn = Mongo::Connection.new
			@mongo_db   = @mongo_conn['ares']
			@mongo_coll = @mongo_db['monitoring']
		end

		def send_info_request
			msg = {
				:msg => "ping"
			}

			@slave.publish msg.to_json
		end

		def process_info_response(response)
			@mongo_coll.insert(response)
		end

		def run()
			Agent.log "Ares::Master.run()"
			
			EventMachine.run do
				Agent.log "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."
				
				# Connect to amqp host
				connect()

				# Create necessary exchanges
				create_exchanges()
				
				# Subscribe for slave messages
				@channel.queue(Agent.generate_queue_name, :auto_delete => true).bind(@master).subscribe do |payload|
					Agent.log "Received a message: #{payload}."

					msg = JSON.parse(payload)
					if(msg["msg"] == "pong")
						process_info_response(msg)
					end
				end

				# Publish some test data in a bit, after all queues are declared & bound
				EventMachine.add_periodic_timer(1.0) do
					# Publish to slave fanout
					send_info_request()
				end
			end
		end
	end # Master
end

if __FILE__ == $0
	Ares::Master.new.run()
end