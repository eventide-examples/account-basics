require_relative '../gems/bundler/setup'

require 'eventide/postgres'


message_store_url = ENV['MESSAGE_STORE_URL']
message_store_url = ::URI.parse(message_store_url)

host = message_store_url.host
port = message_store_url.port
user = message_store_url.user

dbname = message_store_url.path.delete_prefix('/')

message_store_settings = MessageStore::Postgres::Settings.build({
  :host => host,
  :port => port,
  :user => user
})

message_store_session = MessageStore::Postgres::Session.build(settings: message_store_settings)


class Deposit
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
end

class Withdraw
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
end


message_classes = [Deposit, Withdraw]
account_ids = ['123', '456']
amounts = [1, 11, 111]

loop do
  message_class = message_classes.sample
  account_id = account_ids.sample
  amount = amounts.sample
  time = Clock.iso8601

  message = message_class.new
  message.account_id = account_id
  message.amount = amount
  message.time = time

  stream_name = "account:command-#{account_id}"

  Messaging::Postgres::Write.(message, stream_name, session: message_store_session)
end
