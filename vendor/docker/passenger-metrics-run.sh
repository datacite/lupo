#!/bin/bash
cd /home/app/webapp
# Wait for Passenger to start
sleep 30
exec /sbin/setuser app vendor/docker/passenger-metrics.sh 2>&1