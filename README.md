## Benchmarking

The `benchmarking/` directory contains a powerful test suite to simulate a large number of devices. You will need linux on the host machine and an available ethernet interface(you need a physical ethernet port or adaptor). You will also need adequate RAM, depending on how large your benchmark is. as a rough guide, 1500 subscribers and 800 publishers requires ~9GB RAM. 

### How It Works
1.  **Network Setup:** The `setup.bash` script creates a `macvlan` network and uses `nmap` to find available IPs on your LAN.
2.  **Gateway Simulation:** For each available IP, it launches a "gateway" container. This container uses `tc` (Traffic Control) to simulate realistic network conditions like latency, jitter, and packet loss for all traffic passing through it. Be sure to adjust this if running on production server, where network delay already exists!
3.  **Client Simulation:** The `run_publishers.bash` and `run_subscribers.bash` scripts then launch thousands of `nats-box` containers. Each container connects through one of the simulated gateways to the NATS server, creating a realistic, high-churn, high-volume environment.

### Running the Benchmark
The main controller script orchestrates the entire process. Quite a few parameters to be dealt with, see config.bash for all options
.There are a a few [sysctl](https://man7.org/linux/man-pages/man8/sysctl.8.html) parameters to configure, see [99-high-perf-net.conf](./99-high-perf-net.conf) for specifics:
```shell
sudo sysctl -p /etc/sysctl.d/99-high-perf-net.conf
```

These parameters can lead to large amounts of network info being cached so make sure to reboot after running benchmark to go back to your system's defaults.

**Usage:**
```shell
sudo ./benchmarking/controller.bash --ca <path/to/ca.crt> --lb-ip <NATS_LOADBALANCER_IP> [OPTIONS]
Usage: ./controller.bash --creds <file> --ca <file> --lb-ip <ip> [OPTIONS]

This script runs a NATS benchmark using multiple Docker containers. Not comprehensive, see config.bash for all configurable settings.

REQUIRED ARGUMENTS:
  -a, --ca FILE         Path to the CA certificate file for TLS.
  -p, --lb-ip IP        The IP address of the NATS load balancer.

PUBLISHER OPTIONS:
  --pub-limit INT       Total number of publisher containers. (Default: 200)
  --pub-batch INT       Number of publishers to start per interval. (Default: 20)
  --interval SECS       Seconds between starting publisher batches. (Default: 60)

SUBSCRIBER OPTIONS:
  --sub-limit INT       Max number of concurrent subscriber containers. (Default: 850)
  --sub-batch INT       Max subscribers to add/remove each second. (Default: 30)

GENERAL OPTIONS:
  -i, --interface IFACE Name of the parent network interface. (Default: auto-detected)
  -n, --num-subjects INT Number of unique subjects. (Default: 50)
  -k, --num-ips INT     Number of unique 'gateway' IPs/networks. (Default: 35)
  -s, --spread SECS     Max random delay (in seconds) before a container starts publishing. (Default: 15)
  -h, --help            Display this help message and exit.

```