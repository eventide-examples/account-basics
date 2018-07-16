# A Basic Microservice Example Using Pub/Sub and Event Sourcing

This example provides a one-file implementation of the various parts of an autonomous, evented service in one place, including a handler, events, commands, entities, a projection, a consumer, and the service startup script.

The [service.rb](https://github.com/eventide-examples/account-basics/blob/master/service.rb) file has all the things.

To start the service, open a terminal and run `start-service.sh`.

Once the service is running, it waits for new messages.

To feed the service new messages, open a terminal and run `script/produce-messages.sh`.

This is example is built using the [Eventide](http://docs.eventide-project.org/) toolkit.

## Setup

Run `scripts/setup.sh` to install the dependencies and create the message store Postgres database.

``` bash
./setup.sh
```

Dependencies are installed locally in the `gems` directory.

For more information on the message store database, see: [http://docs.eventide-project.org/user-guide/message-store/install.html](http://docs.eventide-project.org/user-guide/message-store/install.html)

## Production Readiness

This is not a production-ready implementation. It's a basic introduction.

It doesn't demonstrate protections for idempotence and concurrency.

For an example that is more representative of production-ready evented autonomous service implementation, see: [https://github.com/eventide-examples/account-component](https://github.com/eventide-examples/account-component).
