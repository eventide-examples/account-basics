#!/usr/bin/env bash

set -x

LOG_TAGS=write,-message_store \
MESSAGE_STORE_URL="postgres://message_store@127.0.0.1:5432/message_store" \
ruby script/produce_messages.rb
