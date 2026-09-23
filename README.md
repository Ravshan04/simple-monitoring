# Simple Monitoring

Project URL: https://roadmap.sh/projects/simple-monitoring-dashboard

This project installs Netdata on a Linux system, configures a basic monitoring
dashboard, adds a custom chart with StatsD, and creates a CPU alert for local
testing.

## What Is Included

- `setup.sh` - installs Netdata and applies local configuration
- `test_dashboard.sh` - sends a custom metric and creates CPU load
- `cleanup.sh` - removes Netdata and local project configuration
- `config/health.d/local-cpu.conf` - alert when CPU usage is above 80%
- `config/statsd.d/simple_monitoring.conf` - custom StatsD chart

## Requirements

- Linux server or VM
- `sudo` access
- `curl`
- Browser access to Netdata on port `19999`

Netdata monitors CPU, memory, disk I/O, network, processes, and many other
metrics automatically after installation.

## 1. Install Netdata

Clone this repository on the Linux server, then run:

```bash
chmod +x setup.sh test_dashboard.sh cleanup.sh
sudo ./setup.sh
```

The script uses Netdata's official `kickstart.sh` installer in non-interactive
mode and installs the stable release channel by default.

Optional:

```bash
sudo RELEASE_CHANNEL=nightly ./setup.sh
```

## 2. Access the Dashboard

On the server:

```bash
curl -I http://localhost:19999
```

Recommended access from your laptop:

```bash
ssh -L 19999:localhost:19999 user@server-ip
```

Then open:

```text
http://localhost:19999
```

If this is a temporary lab server and you intentionally want public access, allow
port `19999` in the firewall and open:

```text
http://server-ip:19999
```

## 3. Custom Dashboard Aspect

This project adds a custom StatsD chart called:

```text
simple_monitoring / Local load test signal
```

The chart is configured in:

```text
/etc/netdata/statsd.d/simple_monitoring.conf
```

The test script sends a gauge metric to Netdata's local StatsD listener:

```text
simple_monitoring.load_test_score
```

## 4. CPU Alert

This project adds a local health alert:

```text
local_cpu_usage_80
```

It watches the `system.cpu` chart and triggers:

- warning above `80%`
- critical above `90%`

The alert file is installed to:

```text
/etc/netdata/health.d/local-cpu.conf
```

Reload alert configuration manually:

```bash
sudo netdatacli reload-health
```

## 5. Test the Dashboard

Run:

```bash
./test_dashboard.sh
```

The script:

1. Checks that Netdata's API is reachable.
2. Sends sample StatsD values for the custom chart.
3. Creates temporary CPU load for about 60 seconds.

Optional:

```bash
LOAD_SECONDS=120 LOAD_PROCESSES=2 ./test_dashboard.sh
```

After running it, open the dashboard and check:

- CPU usage under `System`
- memory usage under `System`
- disk I/O under `Disks`
- custom chart under `simple_monitoring`
- alert status for `local_cpu_usage_80`

## 6. Cleanup

Run:

```bash
sudo ./cleanup.sh
```

This stops Netdata, runs the Netdata uninstaller when available, removes package
installs as a fallback, and deletes the local Netdata cache/log directories.

## Verification Checklist

- [ ] Netdata installed successfully.
- [ ] `systemctl status netdata` shows the service is running.
- [ ] Dashboard opens at `http://localhost:19999`.
- [ ] CPU, memory, and disk I/O charts are visible.
- [ ] Custom StatsD chart appears after running `test_dashboard.sh`.
- [ ] CPU alert `local_cpu_usage_80` is loaded.
- [ ] Cleanup script removes Netdata when tested on a disposable system.

## Useful Commands

```bash
systemctl status netdata
sudo journalctl -u netdata -n 100 --no-pager
curl http://localhost:19999/api/v1/info
curl "http://localhost:19999/api/v1/alarms?all"
curl "http://localhost:19999/api/v1/charts" | grep simple_monitoring
```

## References

- roadmap.sh Simple Monitoring Dashboard: https://roadmap.sh/projects/simple-monitoring-dashboard
- Netdata Linux installation: https://learn.netdata.cloud/docs/netdata-agent/installation/linux
- Netdata alert configuration: https://learn.netdata.cloud/docs/alerts-&-notifications/alert-configuration-reference
- Netdata StatsD collector: https://learn.netdata.cloud/docs/collecting-metrics/statsd
