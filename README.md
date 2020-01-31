# A Basic Microservice Example Using Pub/Sub and Event Sourcing

This example provides a one-file implementation of the various parts of an autonomous, evented service, including a handler, events, commands, entities, entity snapshotting, a projection, a consumer, consumer offset recording, and the service startup script.

The [service.rb](https://github.com/eventide-examples/account-basics/blob/master/service.rb) file has all the things.

To start the service, open a terminal and run `start-service.sh`.

Once the service is running, it waits for new messages.

To feed the service new messages, open a terminal and run `script/produce-messages.sh`.

This is example is built using the [Eventide](http://docs.eventide-project.org/) toolkit.

## Setup

Run `script/setup.sh` to install the dependencies and create the message store Postgres database.

``` bash
script/setup.sh
```

Dependencies are installed locally in the `gems` directory.

For more information on the message store database, see: [http://docs.eventide-project.org/user-guide/message-db/](http://docs.eventide-project.org/user-guide/message-db/)

## The Code

The service is a rudimentary implementation of accounts, including deposits, withdrawals, and insufficient funds handling.

``` ruby
# Deposit command message
# Send to the account service to effect a deposit
class Deposit
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
end

# Deposited event message
# Event is written by the handler when a deposit is successfully processed
class Deposited
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
  attribute :processed_time, String
end

# Withdraw command message
# Send to the account service to effect a withdrawal
class Withdraw
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
end

# Withdrawn event message
# Event is written by the handler when a withdrawal is successfully processed
class Withdrawn
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
  attribute :processed_time, String
end

# WithdrawalRejected event message
# Event is written by the handler when a withdrawal cannot be successfully
# processed, as when there are insufficient funds
class WithdrawalRejected
  include Messaging::Message

  attribute :account_id, String
  attribute :amount, Numeric
  attribute :time, String
end

# Account entity
# The account service's model object
class Account
  include Schema::DataStructure

  attribute :id, String
  attribute :balance, Numeric, default: 0

  def deposit(amount)
    self.balance += amount
  end

  def withdraw(amount)
    self.balance -= amount
  end

  def sufficient_funds?(amount)
    balance >= amount
  end
end

# Account transformation to and from JSON for entity snapshotting
class Account
  module Transform
    # When reading: Convert hash to Account
    def self.instance(raw_data)
      Account.build(raw_data)
    end

    # When writing: Convert Account to hash
    def self.raw_data(instance)
      instance.to_h
    end
  end
end

# Account entity projection
# Applies account events to an account entity
class Projection
  include EntityProjection

  entity_name :account

  apply Deposited do |deposited|
    amount = deposited.amount
    account.deposit(amount)
    account.id = deposited.account_id
  end

  apply Withdrawn do |withdrawn|
    amount = withdrawn.amount
    account.withdraw(amount)
    account.id = withdrawn.account_id
  end
end

# Account entity store
# Projects an account entity and keeps a cache of the result
class Store
  include EntityStore

  category :account
  entity Account
  projection Projection
  reader MessageStore::Postgres::Read
  snapshot EntitySnapshot::Postgres, interval: 5
end

# Account command handler with withdrawal implementation
# Business logic for processing a withdrawal
class Handler
  include Messaging::Handle
  include Messaging::StreamName

  dependency :write, Messaging::Postgres::Write
  dependency :clock, Clock::UTC
  dependency :store, Store

  def configure
    Messaging::Postgres::Write.configure(self)
    Clock::UTC.configure(self)
    Store.configure(self)
  end

  category :account

  handle Deposit do |deposit|
    account_id = deposit.account_id

    time = clock.iso8601

    deposited = Deposited.follow(deposit)
    deposited.processed_time = time

    stream_name = stream_name(account_id)

    write.(deposited, stream_name)
  end

  handle Withdraw do |withdraw|
    account_id = withdraw.account_id

    account = store.fetch(account_id)

    time = clock.iso8601

    stream_name = stream_name(account_id)

    unless account.sufficient_funds?(withdraw.amount)
      withdrawal_rejected = WithdrawalRejected.follow(withdraw)
      withdrawal_rejected.time = time

      write.(withdrawal_rejected, stream_name)

      return
    end

    withdrawn = Withdrawn.follow(withdraw)
    withdrawn.processed_time = time

    write.(withdrawn, stream_name)
  end
end

# The consumer dispatches in-bound messages to handlers
# Consumers have an internal reader that reads messages from a single stream
# Consumers can have many handlers
class AccountConsumer
  include Consumer::Postgres

  handler Handler
end

# The "Component" module maps consumers to their streams
# Until this point, handlers have no knowledge of which streams they process
# Starting the consumers starts the stream readers and gets messages
# flowing into the consumer's handlers
module Component
  def self.call
    account_command_stream_name = 'account:command'
    AccountConsumer.start(account_command_stream_name)
  end
end

# ComponentHost is the runnable part of the service
# Register the component module with the component host, then start the
# component and messages sent to its streams are dispatched to the handlers
component_name = 'account-service'
ComponentHost.start(component_name) do |host|
  host.register(Component)
end
```

## Production Readiness

This basic introduction doesn't demonstrate protections for idempotence and concurrency. Without these considerations, this service isn't production-ready.

For an example that is more representative of production-ready evented autonomous service implementation, including testing, client library implementation, and collaboration with external services, see: [https://github.com/eventide-examples/account-component](https://github.com/eventide-examples/account-component).
