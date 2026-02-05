## Benchmarking

 You will need adequate RAM, depending on how large your benchmark is. as a rough guide, 1500 subscribers and 800 publishers requires ~9GB RAM. By default this setup creates a nats server container to publish to, run with `--noserver` flag and point to the IP of your server with `-p` flag to run without.

 Results for each run are stored in ./bench_logs, here is example output(for a run with all artificial network conditions set to zero), first column is IP of container which is a unique ID and tells you what gateway it belongs to, and the second column is latency in milliseconds(there is so much noise with traffic control that further precision is of questionable use):

 ```shell
 10.10.2.3 2
10.10.8.3 0
10.10.21.3 1
10.10.2.3 0
10.10.8.3 0
10.10.18.3 0
10.10.29.3 0
10.10.21.3 0
10.10.2.3 0
10.10.8.3 0
10.10.29.3 0
10.10.18.3 0
10.10.21.3 0
10.10.2.3 0
10.10.8.3 0
10.10.29.3 0
10.10.18.3 0
10.10.21.3 0
10.10.2.3 0
```

### Quickstart

```shell
./controller.bash -a certificates/rootCA.crt -p 10.11.0.2
```

### How It Works
1.  **Network Setup:** The `setup.bash` script creates a clock container, optionally a server.
2.  **Gateway Simulation:** For each available IP, it launches a "gateway" container. This container uses `tc` (Traffic Control) to simulate realistic network conditions like latency, jitter, and packet loss for all traffic passing through it. Be sure to adjust this if running on production server, where network delay already exists!
3.  **Client Simulation:** The `run_publishers.bash` and `run_subscribers.bash` scripts then launch thousands of `nats-box` containers. Each container connects through one of the simulated gateways to the NATS server, creating a realistic, high-churn, high-volume environment.

### Running the Benchmark
The main controller script orchestrates the entire process. Quite a few parameters to be dealt with, see config.bash for all options. It's reccomended to configure the sysctl params but it does run without it for runs with low numbers of overall containers. There are a a few [sysctl](https://man7.org/linux/man-pages/man8/sysctl.8.html) parameters to configure, see [99-high-perf-net.conf](./99-high-perf-net.conf) for specifics:
```shell
sudo cp ./99-high-perf-net.conf /etc/sysctl.d/99-high-perf-net.conf
sudo sysctl -p /etc/sysctl.d/99-high-perf-net.conf
```

These parameters can lead to large amounts of network info being cached so make sure to reboot after running benchmark to go back to your system's defaults.

Logs are written to bench_logs folder, first heading is ip of client container and second is just latency in ms. When using extreme values for packet loss this can cause unexpectedly high latency of >1sec so be warned.

**Usage:**
```shell

Usage: ./controller.bash --ca <file> --lb-ip <ip> [OPTIONS]

This script runs a NATS benchmark using multiple Docker containers. Not comprehensive, see config.bash for all settings that can be set

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
  -n, --num-subjects INT Number of unique subjects. (Default: 50)
  -k, --num-ips INT     Number of unique 'gateway' IPs/networks. (Default: 35)
  -s, --spread SECS     Max random delay (in seconds) before a container starts publishing. (Default: 15)
  --noserver            Disable network simulation. Skips server creation and connects 
                        gateways to the host network.
  -h, --help            Display this help message and exit.