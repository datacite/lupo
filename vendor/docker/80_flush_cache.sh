#!/bin/sh
/sbin/setuser www-data bundle exec rake memcached:flush
