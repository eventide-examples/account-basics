#!/usr/bin/env bash

script/install-gems.sh

bundle exec evt-pg-recreate-db
