#!/usr/bin/env bash

psql message_store -U message_store -P pager=off -c "SELECT DISTINCT type, count(type) FROM messages GROUP BY type ORDER BY count DESC;"

# psql message_store -U message_store -P pager=off -c "SELECT DISTINCT stream_name, count(stream_name) FROM messages GROUP BY stream_name ORDER BY count DESC;"

psql message_store -U message_store -P pager=off -c "SELECT count(*) FROM messages;"
