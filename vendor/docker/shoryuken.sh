#!/bin/sh
cd /home/app/webapp
exec 2>&1
if [ "$AWS_REGION" ]; then
  exec /sbin/setuser app bundle exec shoryuken -R -C config/shoryuken.yml
fi
