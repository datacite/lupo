#!/bin/sh
cd /home/app/webapp
exec 2>&1
# If AWS_REGION is set and not explicitly disabled with DISABLE_QUEUE_WORKER, start shoryuken
if [ -n "$AWS_REGION" ] && [ -z "$DISABLE_QUEUE_WORKER" ]; then
  exec /sbin/setuser app bundle exec shoryuken -R -C config/shoryuken.yml
fi
