require_relative '../gems/bundler/setup'
require 'eventide/postgres'

module StreamScan
  class Postgres
    include Initializer
    include Dependency
    include Log::Dependency

    initializer :stream_name, :position, :batch_size, :condition

    dependency :read, MessageStore::Postgres::Read

    def self.build(stream_name, position: nil, batch_size: nil, session: nil, &condition)
      instance = new(stream_name, position, batch_size, condition)

      instance.configure(session: session)

      instance
    end

    def configure(session: nil)
      MessageStore::Postgres::Read.configure(self, stream_name, position: position, batch_size: batch_size, session: session)
    end

    def self.call(stream_name, position: nil, batch_size: nil, session: nil, &condition)
      instance = build(stream_name, position: position, batch_size: batch_size, session: session, &condition)
      instance.()
    end

    def call
      logger.trace(tag: :scan) { "Scanning stream (Stream Name: #{stream_name}, Position: #{position.inspect}, Batch Size: #{batch_size.inspect})" }

      count = 0
      message_data = nil
      read.() do |read_message_data|
        count = count + 1

        met = condition.(read_message_data)

        if met
          message_data = read_message_data
          break
        end
      end

      logger.info(tag: :scan) { "Scanned stream (Stream Name: #{stream_name}, Messages Scanned: #{count}, Position: #{position.inspect}, Batch Size: #{batch_size.inspect})" }

      message_data
    end
  end
end

# Usage
ENV['MESSAGE_STORE_SETTINGS_PATH'] = './settings.json'
ENV['LOG_LEVEL'] = 'trace'
ENV['LOG_TAGS'] = 'scan'

stream_name = 'account-123'

message_data = StreamScan::Postgres.(stream_name) do |message_data|
  message_data.position == 11
end

pp message_data
