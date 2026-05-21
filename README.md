[![Docker](https://github.com/Seji64/SniDust/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Seji64/SniDust/actions/workflows/docker-publish.yml)

# SniDust
**SmartDNS Proxy to hide your GeoLocation.** 
SniDust is a powerful tool based on **DnsDist** and **Nginx**, designed to proxy DNS requests and spoof your origin IP to bypass geo-restrictions for various services.

## Supported Services
SniDust is optimized for services such as:
- Zattoo
- Yallo.tv
- Netflix
- Hulu
- Amazon Prime
- SRF.ch (Live TV)

## Prerequisites
You will need a VPS or a Root Server with [Docker](https://www.docker.com/) installed.

## Usage

### 1. Determine Your Client Public IP
Run this on the device you will be using to connect to the proxy:
```bash
curl https://ifconfig.co
```
*Example: Let's assume your client public IP is `10.111.123.7` or you use a DynDNS domain like `myDynDNSDomain.no-ip.com`.*

### 2. Determine Your Server Public IP
Run this on the server where SniDust will be hosted:
```bash
curl https://ifconfig.co
```
*Example: Let's assume your server public IP is `10.111.123.8`.*

### 3. Deploy SniDust

#### Using Docker Run
```bash
docker run -d \
  --name snidust \
  -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7, myDynDNSDomain.no-ip.com" \
  -e EXTERNAL_IP=10.111.123.8 \
  -p 443:8443 -p 80:8080 -p 53:5300/udp \
  ghcr.io/seji64/snidust:latest
```

#### Using Docker Compose
```yaml
version: '3.3'
services:
    snidust:
        container_name: snidust
        image: 'ghcr.io/seji64/snidust:latest'
        environment:
            - TZ=Europe/Berlin
            - 'ALLOWED_CLIENTS=127.0.0.1, 10.111.123.7, myDynDNSDomain.no-ip.com'
            - 'EXTERNAL_IP=10.111.123.8'
            - SPOOF_ALL_DOMAINS=false # Set to true to spoof ALL domains (not recommended)
            # - 'DYNDNS_CRON_SCHEDULE=*/1 * * * *' # Custom cron interval for DynDNS. Default: '*/15 * * * *'
        ports:
            - 443:8443
            - 80:8080
            - 53:5300/udp
```

### 4. Verification
Check the container logs to ensure everything is running correctly:
```bash
docker logs snidust
```
You should see messages indicating that the webserver is launched and the upstream DNS servers (Google, Cloudflare) are marked as 'up'.

### 5. Client Configuration
Change the DNS server settings on your client device to the **Public IP of your server** (`10.111.123.8`). Your GeoLocation is now hidden!

---

## Configuration & Environment Variables

### Core Settings
| Variable | Default | Description |
| :--- | :--- | :--- |
| `ALLOWED_CLIENTS` | `127.0.0.1` | Comma-separated list of allowed IPs or DynDNS domains. |
| `ALLOWED_CLIENTS_FILE` | *(empty)* | Path to a file containing the ACL (allows reloading without restart). |
| `EXTERNAL_IP` | *(empty)* | The public IP of the server to be used for spoofing. |
| `SPOOF_ALL_DOMAINS` | `false` | If `true`, all DNS queries are spoofed regardless of the domain list. |
| `INSTALL_DEFAULT_DOMAINS` | `true` | Whether to install the default domain lists provided by the repo. |
| `DYNDNS_CRON_SCHEDULE` | `*/15 * * * *` | Schedule for DynDNS updates. |

### DNSDist Performance & Security
| Variable | Default | Description |
| :--- | :--- | :--- |
| `DNSDIST_RATE_LIMIT_DISABLE` | `false` | Set to `true` to disable rate limiting. |
| `DNSDIST_RATE_LIMIT_WARN` | `800` | Warning threshold in queries per second (qps). |
| `DNSDIST_RATE_LIMIT_BLOCK` | `1000` | Blocking threshold in qps. |
| `DNSDIST_RATE_LIMIT_BLOCK_DURATION` | `360` | Duration (seconds) for which a client is blocked. |
| `DNSDIST_RATE_LIMIT_EVAL_WINDOW` | `60` | Evaluation window in seconds. |
| `DNSDIST_PACKAGE_CACHE_ENABLED` | `false` | Enables packet caching to reduce latency. |
| `DNSDIST_PACKAGE_CACHE_SIZE` | `50000` | Maximum number of entries in the packet cache. |
| `DNSDIST_UPSTREAM_POOL_NAME` | `upstream` | Name of the upstream pool. Change this if using a custom pool. |
| `DNSDIST_UPSTREAM_CHECK_INTERVAL` | `10` | Interval (seconds) for checking upstream server health. |

---

## Advanced Setups

### DNS over TLS (DoT)
For examples on how to set up DoT, refer to `docker-compose.dot.yml` and `docker-compose.acme.sh-dot.yml` in the repository.

### Custom Upstream DNS Servers
To use your own upstream DNS servers instead of the defaults (Google/Cloudflare):
1. Create a file named `99-customUpstream.conf`.
2. Define your servers using the [DNSDist configuration syntax](https://dnsdist.org/reference/config.html#newServer).
   *Example:*
   ```
   newServer({address="192.0.2.1", name="custom1", pool="customUpstream"})
   newServer({address="192.0.2.2", name="custom2", pool="customUpstream"})
   ```
3. Set the environment variable `DNSDIST_UPSTREAM_POOL_NAME` to your pool name (e.g., `customUpstream`).
4. Mount the file into the container:
   ```yaml
   volumes:
     - ~/99-customUpstream.conf:/etc/dnsdist/conf.d/99-customUpstream.conf
   ```

### Custom Domain Lists
To add domains not included by default, create a file named `99-custom.lst` and mount it:
```bash
docker run --name snidust \
  -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7" \
  -e EXTERNAL_IP=10.111.123.8 \
  -p 443:8443 -p 80:8080 -p 53:5300/udp \
  -v ~/99-custom.lst:/etc/snidust/domains.d/99-custom.lst:ro \
  ghcr.io/seji64/snidust:latest
```

### Dynamic Reloading
You can reload configurations without restarting the container by sending a specific DNS query:

- **Reload ACLs:** `dig @<SERVER_IP> reload.acl.snidust.local`
- **Reload Domain Lists:** `dig @<SERVER_IP> reload.domainlist.snidust.local`

### Custom Nginx Configuration
If you need a custom `nginx.conf` for reverse proxying or performance tuning, mount it to `/etc/nginx/nginx.conf`:
```yaml
volumes:
  - '~/nginx.conf:/etc/nginx/nginx.conf:ro'
```

---

## Troubleshooting

### Port 53 is already in use
If you encounter an error stating that port 53 is occupied, it is likely due to another service (like Pi-hole) or `systemd-resolved` on Linux.
Follow this [Guide](https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html) to free up the port.

## Credits
Based on the following projects:
- [dnsdist.org](https://dnsdist.org/)
- [nginx.org](https://www.nginx.com)
- [wilmaa-proxy](https://github.com/andykimpe/wilmaa-proxy)
- [unblock-proxy.sh](https://github.com/suuhm/unblock-proxy.sh)
- [netflix-proxy](https://github.com/ab77/netflix-proxy)

## Star History
<a href="https://star-history.com/#Seji64/SniDust&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Seji64/SniDust&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Seji64/SniDust&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Seji64/SniDust&type=Date" />
 </picture>
</a>
