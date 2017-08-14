#!/bin/sh
cd /home/app/webapp
exec 2>&1
exec /sbin/setuser app bundle exec sidekiq -e production --config config/sidekiq.yml
