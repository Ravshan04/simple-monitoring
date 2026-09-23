#!/usr/bin/env bash
set -euo pipefail

NETDATA_URL="${NETDATA_URL:-http://localhost:19999}"
LOAD_SECONDS="${LOAD_SECONDS:-60}"
LOAD_PROCESSES="${LOAD_PROCESSES:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}"

send_statsd_metric() {
  local value="$1"
  printf 'simple_monitoring.load_test_score:%s|g\n' "${value}" >/dev/udp/127.0.0.1/8125 || true
}

check_dashboard() {
  if ! curl -fsS "${NETDATA_URL}/api/v1/info" >/dev/null; then
    echo "Netdata dashboard is not reachable at ${NETDATA_URL}"
    exit 1
  fi
}

create_load() {
  echo "Creating CPU load for ${LOAD_SECONDS}s with ${LOAD_PROCESSES} worker(s)."

  if command -v stress-ng >/dev/null 2>&1; then
    stress-ng --cpu "${LOAD_PROCESSES}" --timeout "${LOAD_SECONDS}s" --metrics-brief
    return
  fi

  local pids=()
  for _ in $(seq 1 "${LOAD_PROCESSES}"); do
    (end=$((SECONDS + LOAD_SECONDS)); while [[ "${SECONDS}" -lt "${end}" ]]; do :; done) &
    pids+=("$!")
  done

  wait "${pids[@]}"
}

check_dashboard

for value in 10 35 65 90 45; do
  send_statsd_metric "${value}"
  sleep 1
done

create_load

send_statsd_metric 100

echo "Dashboard test complete."
echo "Open ${NETDATA_URL} and check:"
echo "- CPU chart under System"
echo "- Disk I/O charts under Disks"
echo "- Custom chart: simple_monitoring / Local load test signal"
echo "- Alert: local_cpu_usage_80"
