#!/usr/bin/env bash

set -x

LOG_TAGS=write,-message_store \
MESSAGE_STORE_SETTINGS_PATH=./script/settings.json \
ruby script/produce_messages.rb
