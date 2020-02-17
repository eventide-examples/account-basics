#!/usr/bin/env bash

script/install-gems.sh

bundle exec mdb-recreate-db
