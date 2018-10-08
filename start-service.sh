#!/usr/bin/env bash

set -x

LOG_TAGS=handle,write,-message_store,store,cache,snapshot \
MESSAGE_STORE_URL="postgres://message_store@127.0.0.1:5432/message_store" \
ruby service.rb
