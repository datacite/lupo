#!/bin/sh
cd /var/www
exec 2>&1
if [ "$AWS_REGION" ]; then
  exec /sbin/setuser www-data bundle exec shoryuken -R -C config/shoryuken.yml
fi
