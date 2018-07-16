#!/usr/bin/env bash

set -x

LOG_TAGS=handle,write,-message_store,store,cache,snapshot \
MESSAGE_STORE_SETTINGS_PATH=./settings.json \
ruby service.rb
