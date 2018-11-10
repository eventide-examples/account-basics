require_relative '../gems/bundler/setup'
require 'eventide/postgres'

require_relative '../service.rb'

module Queries
  class EntityQuery
    include Initializer
    include Dependency
    include Log::Dependency

    initializer :stream_name, :entity, :projection, :condition

    dependency :read, MessageStore::Postgres::Read

    def self.build(entity_id, category, entity_class, projection_class, session: nil, &condition)
      stream_name = MessageStore::StreamName.stream_name(category, entity_id)

      entity = entity_class.new
      projection = projection_class.new(entity)

      instance = new(stream_name, entity, projection, condition)

      MessageStore::Postgres::Read.configure(instance, stream_name, session: session)

      instance
    end

    def self.call(entity_id, category, entity_class, projection_class, session: nil, &condition)
      instance = build(entity_id, category, entity_class, projection_class, session: session, &condition)
      instance.()
    end

    def call
      logger.trace(tag: :query) { "Querying entity (Entity Class: #{entity.class}, Projection Class: #{projection.class}, Stream Name: #{stream_name})" }

      count = 0
      read.() do |message_data|
        continue = condition.call(message_data)
        break unless continue

        count = count + 1
        projection.(message_data)
      end

      logger.info(tag: :query) { "Querying entity (Entity Class: #{entity.class}, Projection Class: #{projection.class}, Stream Name: #{stream_name}, Events Projected: #{count})" }

      entity
    end
  end
end


# Usage
ENV['MESSAGE_STORE_SETTINGS_PATH'] = './settings.json'
ENV['LOG_LEVEL'] = 'trace'
ENV['LOG_TAGS'] = 'query'

time = Time.new(2000, 2, 1)

account = Queries::EntityQuery.('123', :account, Account, Projection) do |message_data|
  message_time = ::Time.parse(message_data.data[:time])
  message_time <= time
end

pp account
