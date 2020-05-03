#!/bin/sh
if [ "${SERVER_ROLE}" != "secondary" ]; then
  /sbin/setuser www-data bundle exec rake db:migrate
  /sbin/setuser www-data bundle exec rake db:seed
fi
