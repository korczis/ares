#!/usr/bin/env ruby
# encoding: utf-8

require 'bundler'
require 'rubygems'
require 'amqp'

module Ares
	class Agent
		@@AMQP_HOST = "localhost"

		def self.log(msg)
			ts = Time.now.strftime("%Y/%m/%d %H:%M:%S")
			puts "[#{ts}] #{msg}"
		end

		def connect()
			@connection = AMQP.connect(:host => @@AMQP_HOST)
		end

		def create_exchanges()
			# Create new channel
			@channel  = AMQP::Channel.new(@connection)
			
			# Create slave exchange, mark it as persistent
			@slave = @channel.fanout("ares.slave", :auto_delete => false)

			# Create master exchange, mark it as persistent
			@master = @channel.fanout("ares.master", :auto_delete => false)
		end

		def self.generate_queue_name
			return Random.rand(1e9).to_s
		end
	end # Monitor
end

if __FILE__ == $0
	Ares::Agent.new.run()
end