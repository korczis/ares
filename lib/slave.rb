#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler'
require 'rubygems'
require 'amqp'
require 'json'

# sys-utils - http://sysutils.rubyforge.org/
require 'sys/admin'
require 'sys/cpu'
require 'sys/host'
require 'sys/filesystem'
require 'sys/proctable'
require 'sys/uname'
require 'sys/uptime'

require File.join(File.dirname(__FILE__), 'agent')

module Ares
	class Slave < Agent		
		include Sys

		def send_info_response
			host = {
				:hostname =>  Sys::Host.hostname,
				:ip => Sys::Host.ip_addr
			}

			msg = {
				:msg => "pong",
				:host => host
			} 

			@master.publish msg.to_json
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
				@channel.queue(Agent.generate_queue_name, :auto_delete => true).bind(@slave).subscribe do |payload|
					Agent.log "Received a message: #{payload}."

					msg = JSON.parse(payload)
					if(msg["msg"] == "ping")
						send_info_response()
					end
				end
			end
		end
	end # Slave
end

if __FILE__ == $0
	Ares::Slave.new.run()
end