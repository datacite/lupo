#!/bin/sh
cd /var/www
exec 2>&1
exec /sbin/setuser www-data bundle exec puma -C config/puma.rb
