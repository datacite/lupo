#!/bin/bash
# passenger-metrics.sh
# Collects Passenger worker statistics and publishes to CloudWatch.

set -euo pipefail

# Ensure required ENVVARS exist
AWS_REGION="${AWS_REGION:-eu-west-1}"
SERVER_NAME="${SERVERNAME:-unknown}"

# Set up global variables
NAMESPACE="Custom/LupoPassenger"
SERVICE_NAME="${SERVER_NAME%.datacite.org}" # client-api.datacite.org -> client-api
INTERVAL=15

log() {
  echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] passenger-metrics: $*" >&2
}

publish_metrics() {
  # Input: "$max_workers" "$current_workers" "$request_queue" "$active_workers" "$idle_workers" "$utilisation"
  local max_workers="$1"
  local current_workers="$2"
  local request_queue="$3"
  local active_workers="$4"
  local idle_workers="$5"
  local utilisation="$6"
  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  # Publish all metrics in a single API call
  aws cloudwatch put-metric-data \
    --region "$AWS_REGION" \
    --namespace "$NAMESPACE" \
    --storage-resolution 1 \
    --metric-data \
      "MetricName=PassengerMaxWorkers,Value=${max_workers},Unit=Count,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]" \
      "MetricName=PassengerCurrentWorkers,Value=${current_workers},Unit=Count,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]" \
      "MetricName=PassengerRequestQueue,Value=${request_queue},Unit=Count,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]" \
      "MetricName=PassengerActiveWorkers,Value=${active_workers},Unit=Count,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]" \
      "MetricName=PassengerIdleWorkers,Value=${idle_workers},Unit=Count,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]" \
      "MetricName=PassengerWorkerUtilisation,Value=${utilisation},Unit=Percent,Timestamp=${timestamp},Dimensions=[{Name=Service,Value=${SERVICE_NAME}}]"
}

collect_and_publish() {
  # Store passenger-status XML output
  local status_output
  if ! status_output=$(passenger-status --show=xml 2>/dev/null); then
    log "ERROR: passenger-status failed"
    return 1
  fi
 
  local max_workers current_workers request_queue active_workers idle_workers

  # Parse the metrics from the XML
  # On non-zero exit code, default to empty string to trigger the fallback text-mode parser
  max_workers=$(echo "$status_output" | xmllint --format --xpath '//max/text()' - | head -n 1 2>/dev/null || echo "")
  current_workers=$(echo "$status_output" | xmllint --format --xpath '//process_count/text()' - | head -n 1 2>/dev/null || echo "")
  request_queue=$(echo "$status_output" | xmllint --format --xpath '//supergroups/supergroup/group/get_wait_list_size/text()' - | head -n 1 2>/dev/null || echo "")
  active_workers=$(echo "$status_output" | xmllint --format --xpath 'count(//supergroups/supergroup/group/processes/process/sessions/text()[contains(., "1")])' - | head -n 1 2>/dev/null || echo "")
  idle_workers=$(echo "$status_output" | xmllint --format --xpath 'count(//supergroups/supergroup/group/processes/process/sessions/text()[contains(., "0")])' - | head -n 1 2>/dev/null || echo "")



  # If XML parsing didn't work, try text format
  if [[ -z "$max_workers" || -z "$current_workers" ]]; then
    log "XML parsing failed, trying text format"
    status_output=$(passenger-status 2>/dev/null) || return 1

    max_workers=$(echo "$status_output" | grep -oP 'Max pool size\s*:\s*\K[0-9]+' | head -1 || echo "0")
    current_workers=$(echo "$status_output" | grep -oP 'Processes\s*:\s*\K[0-9]+' | head -1 || echo "0")
    request_queue=$(echo "$status_output" | grep -oP 'Requests in top-level queue\s*:\s*\K[0-9]+' | head -1 || echo "0")
    active_workers=$(echo "$status_output" | grep -cP 'Sessions:\s+1' | head -1)
    idle_workers=$(echo "$status_output" | grep -cP 'Sessions:\s+0' | head -1)
    
  fi

  # Default to 0 if still empty
  max_workers="${max_workers:-0}"
  current_workers="${current_workers:-0}"
  request_queue="${request_queue:-0}"
  active_workers="${active_workers:-0}"
  idle_workers="${idle_workers:-0}"

  # Calculate worker utilisation percentage
  local utilisation
  if [[ "$active_workers" -gt "0" ]]; then
    utilisation=$(( (active_workers * 100) / current_workers ))
  else
    utilisation=0
  fi
  
  # Sanity check - do active and idle workers add up to the current workers?
  if [[ $((active_workers + idle_workers)) -ne "$current_workers" ]]; then
    log "WARNING: active + idle workers ($((active_workers + idle_workers))) does not equal current workers ($current_workers)"
  fi

  # Log out values for validation against CloudWatch during testing
  # Only enable this when testing changes locally or in staging, otherwise we'll be very noisy (1 log message per container every 15s!)
  # log "max=$max_workers current=$current_workers queued=$request_queue active=$active_workers idle=$idle_workers util=${utilisation}%"

  # Push metrics to CloudWatch
  publish_metrics "$max_workers" "$current_workers" "$request_queue" "$active_workers" "$idle_workers" "$utilisation"
}

# Main loop
log "Starting Passenger metrics collection for service=$SERVICE_NAME (interval=${INTERVAL}s)"

while true; do
  collect_and_publish || log "WARNING: metrics collection failed, will retry in ${INTERVAL}s"
  sleep "$INTERVAL"
done
