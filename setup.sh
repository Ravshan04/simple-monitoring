#!/usr/bin/env bash
set -euo pipefail

NETDATA_PORT="${NETDATA_PORT:-19999}"
RELEASE_CHANNEL="${RELEASE_CHANNEL:-stable}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script with sudo:"
    echo "sudo $0"
    exit 1
  fi
}

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y curl ca-certificates procps coreutils
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl ca-certificates procps-ng coreutils
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl ca-certificates procps-ng coreutils
  else
    echo "Unsupported package manager. Install curl and ca-certificates manually, then rerun."
    exit 1
  fi
}

install_netdata() {
  curl -fsSL https://get.netdata.cloud/kickstart.sh -o /tmp/netdata-kickstart.sh
  DISABLE_TELEMETRY=1 sh /tmp/netdata-kickstart.sh \
    --non-interactive \
    --release-channel "${RELEASE_CHANNEL}"
}

install_config() {
  install -d -m 0755 /etc/netdata/health.d /etc/netdata/statsd.d
  install -m 0644 "${PROJECT_DIR}/config/health.d/local-cpu.conf" \
    /etc/netdata/health.d/local-cpu.conf
  install -m 0644 "${PROJECT_DIR}/config/statsd.d/simple_monitoring.conf" \
    /etc/netdata/statsd.d/simple_monitoring.conf
}

reload_netdata() {
  systemctl enable netdata
  systemctl restart netdata

  if command -v netdatacli >/dev/null 2>&1; then
    netdatacli reload-health || true
  fi
}

print_status() {
  local host
  host="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo
  echo "Netdata is installed."
  echo "Local dashboard: http://localhost:${NETDATA_PORT}"
  if [[ -n "${host}" ]]; then
    echo "Server dashboard: http://${host}:${NETDATA_PORT}"
  fi
  echo
  echo "Recommended SSH tunnel from your laptop:"
  echo "ssh -L ${NETDATA_PORT}:localhost:${NETDATA_PORT} user@server-ip"
  echo "Then open: http://localhost:${NETDATA_PORT}"
}

require_root
install_packages
install_netdata
install_config
reload_netdata
print_status
