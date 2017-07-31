#!/bin/bash
rm -r /home/bhargav/Github/auth/spec/dummy/log/sidekiq.log
while IFS='' read -r line || [[ -n "$line" ]]; do
    kill -9 $line
done < "/home/bhargav/Github/auth/spec/dummy/tmp/pids/sidekiq.pid"
