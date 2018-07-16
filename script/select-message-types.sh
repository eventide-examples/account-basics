#!/usr/bin/env bash

psql message_store -U message_store -P pager=off -c "SELECT DISTINCT type FROM messages;"
