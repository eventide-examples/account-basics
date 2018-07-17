require_relative '../gems/bundler/setup'


libraries_dir = ENV['LIBRARIES_HOME']
unless libraries_dir.nil?
  libraries_dir = File.expand_path(libraries_dir)
  $LOAD_PATH.unshift libraries_dir unless $LOAD_PATH.include?(libraries_dir)
end



require 'eventide/postgres'

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

  Messaging::Postgres::Write.(message, stream_name)
end
