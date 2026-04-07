#!/bin/bash
cd /home/app/webapp
# Wait for Passenger to start
sleep 30
# Only run the script if ENABLE_PASSENGER_METRICS is set
if [ -n "$ENABLE_PASSENGER_METRICS" ]; then
  exec /sbin/setuser app vendor/docker/passenger-metrics.sh 2>&1
fi
