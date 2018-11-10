require_relative '../gems/bundler/setup'
require 'eventide/postgres'

require_relative '../service.rb'

module Queries
  class Time
    include Initializer
    include Dependency
    include Log::Dependency

    initializer :stream_name, :time

    dependency :read, MessageStore::Postgres::Read

    def self.build(account_id, time, session: nil)
      stream_name = MessageStore::StreamName.stream_name(:account, account_id)
      instance = new(stream_name, time)
      MessageStore::Postgres::Read.configure(instance, stream_name, session: session)
      instance
    end

    def self.call(account_id, time, session: nil)
      instance = build(account_id, time, session: session)
      instance.()
    end

    def call
      logger.trace(tag: :query) { "Querying account (Stream Name: #{stream_name}, Time: #{time})" }

      account = Account.new

      count = 0
      read.() do |message_data|
        message_time = ::Time.parse(message_data.data[:time])

        if message_time > time
          break
        end

        count = count + 1
        Projection.(account, message_data)
      end

      logger.info(tag: :query) { "Done querying account (Stream Name: #{stream_name}, Time: #{time}, Events Projected: #{count})" }

      account
    end
  end
end

ENV['MESSAGE_STORE_SETTINGS_PATH'] = './settings.json'
ENV['LOG_LEVEL'] = 'trace'
ENV['LOG_TAGS'] = 'query'


time = Time.new(2000, 2, 1)
account = Queries::Time.('123', time)

pp account
