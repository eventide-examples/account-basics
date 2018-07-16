#!/usr/bin/env bash

scripts/install-gems.sh

bundle exec evt-pg-recreate-db
