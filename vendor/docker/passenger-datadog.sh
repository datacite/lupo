#!/bin/sh
exec 2>&1
exec /usr/local/bin/passenger-datadog-monitor -port=8125
