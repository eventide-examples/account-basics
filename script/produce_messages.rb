require_relative '../gems/bundler/setup'

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

day = 0
month = 1

loop do
  message_class = message_classes.sample
  account_id = account_ids.sample
  amount = amounts.sample

  day = day + 1
  time = Time.new(2000, month, day)
  iso_time = Clock.iso8601(time)

  if day == 28
    month = month + 1
    day = 0
  end

  message = message_class.new
  message.account_id = account_id
  message.amount = amount
  message.time = iso_time

  stream_name = "account:command-#{account_id}"

  Messaging::Postgres::Write.(message, stream_name)
end
