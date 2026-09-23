#!/usr/bin/env bash
set -euo pipefail

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this script with sudo:"
    echo "sudo $0"
    exit 1
  fi
}

remove_netdata() {
  if [[ -x /usr/libexec/netdata/netdata-uninstaller.sh ]]; then
    /usr/libexec/netdata/netdata-uninstaller.sh --yes
    return
  fi

  if [[ -x /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh ]]; then
    /opt/netdata/usr/libexec/netdata/netdata-uninstaller.sh --yes
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get purge -y 'netdata*' || true
    apt-get autoremove -y || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf remove -y 'netdata*' || true
  elif command -v yum >/dev/null 2>&1; then
    yum remove -y 'netdata*' || true
  fi
}

remove_leftovers() {
  rm -f /etc/netdata/health.d/local-cpu.conf
  rm -f /etc/netdata/statsd.d/simple_monitoring.conf
  rm -rf /var/cache/netdata /var/lib/netdata /var/log/netdata
}

require_root
systemctl stop netdata 2>/dev/null || true
remove_netdata
remove_leftovers

echo "Netdata cleanup complete."
