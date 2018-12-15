#!/bin/sh
cd vendor/middleman
/sbin/setuser app bundle exec middleman build -e ${RAILS_ENV}
