# This branch is unmaintained. Please migrate to main branch

# SniDust
SmartDNS Proxy to hide your GeoLocation. Based on DnsDist and SniProxy

## Supported Services

- Zattoo
- Yallo.tv
- Netflix
- Hulu
- Amazon Prime
- SRF.ch (live tv)

## Prerequisites

You will need a VPS or a Root Server where you can install [Docker](https://www.docker.com/) (or Docker is already installed).

##  Usage

### Get your Public IP (Client)

```
## run this in your terminal or use your webbrowser
curl https://ifconfig.me
```
For this **example**  lets assume your public ip (of your *client*) is `10.111.123.7`
Since version `v1.0.8` you can also use DynDNS. In this case just use your DynDNS domain eg. `myDynDNSDomain.no-ip.com`

### Get your IP of your Server

```
curl https://ifconfig.me
```
For this **example** lets assume your public ip (of your *server*) is `10.111.123.8`

### Run SniDust on your Server

```
docker run -d --name snidust -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7, myDynDNSDomain.no-ip.com" -e EXTERNAL_IP=10.111.123.8 -p 443:443 -p 80:80 -p 53:5300/udp ghcr.io/seji64/snidust:main
```

Or if you use docker compose:

```yaml
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - ALLOWED_CLIENTS=127.0.0.1, 10.111.123.7, myDynDNSDomain.no-ip.com
            - EXTERNAL_IP=10.111.123.8
            - SPOOF_ALL_DOMAINS=false # Set to true (case sensitive!) if you want to spoof ALL domains.
        ports:
            - 443:443
            - 80:80
            - 53:5300/udp
        image: 'ghcr.io/seji64/snidust:main'
```

### Check logs of the container
```bash
docker logs snidust
```

The logs should look something like this:

```
...
Webserver launched on 127.0.0.1:8083
Marking downstream 1.0.0.1:443 as 'up'
Marking downstream dns.google (8.8.8.8:853) as 'up'
Marking downstream dns.google (8.8.4.4:853) as 'up'
Marking downstream 1.1.1.1:443 as 'up'
Polled security status of version 1.7.1 at startup, no known issues reported: OK
```

### Configure your client

Change your network settings and set the DNS Server as  10.111.123.8 (**PUBLIC_VPS_IP**)

Your GeoLaction should now hidden :-)

## Troubleshooting

### Error Port 53 is already in use

In this case, you are either running another service (like Pi-Hole) that already uses this Port or you likely use a Linux distribution that uses Systemd.

In case Systemd is already using port 53 you can follow this [Guide](https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html) to free up this port.

## Advanced setups

### Configure DNS Rate Limiting
The default is the following:
```
Generate a warning if we detect a query rate above 800 qps *(Query per second)* for at least 60s.
If the query rate rises above 1000 qps for 60 seconds, we'll block the client for 360s.
```
To customize this behavior you can use the following environment variables:
````
DNSDIST_RATE_LIMIT_WARN (default: 800)
DNSDIST_RATE_LIMIT_BLOCK (default: 1000)
DNSDIST_RATE_LIMIT_BLOCK_DURATION (default: 360)
DNSDIST_RATE_LIMIT_EVAL_WINDOW (default: 60)
````

If you want to disable Rate Limiting completely set `DNSDIST_RATE_LIMIT_DISABLE` to `true`

### Use custom Upstream DNS Servers
By default, SniDust is using Cloudflare's and Google's DNS Servers as Upstream.
To use your own/custom upstream DNS Server you have to do the following:

#### Configure and use Custom Upstream Pool
- Create a file named 99-customUpstream.conf
- Use the [DNSDist Documentation](https://dnsdist.org/reference/config.html#newServer) to create you own upstream pool.
  Example:
  ```
  newServer("192.0.2.1", name="custom1", pool="customUpstream")
  newServer("192.0.2.2", name="custom2", pool="customUpstream")
  ```
 - Ensure you have set a `pool` and it is **NOT** named `upstream` (this name is already used by sniDust itself)
 - Set Environment Variable `DNSDIST_UPSTREAM_POOL_NAME` to your pool name *(here: `customUpstream`)*
 - Map your file `99-customUpstream.conf`
   ```
   ...
           volumes:
             - ~/99-customUpstream.conf:/etc/dnsdist/conf.d/99-customUpstream.conf
    ...
   ```
### Add custom domains

In case you want to add custom domains which not included by default, this can be done easily.
Create a file with the name `99-custom.lst`. Insert all your custom domains in this file.

#### Mount it

```bash
docker run --name snidust -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7" -e EXTERNAL_IP=10.111.123.8 -p 443:443 -p 80:80 -p 53:5300/udp -v ~/99-custom.lst:/etc/snidust/domains.d/99-custom.lst:ro ghcr.io/seji64/snidust:main
```

Or if you use docker-compose:

```yaml
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - 'ALLOWED_CLIENTS=127.0.0.1, 10.111.123.7'
            - EXTERNAL_IP=10.111.123.8
        ports:
            - '443:443'
            - '80:80'
            - '53:5300/udp'
        volumes:
            - '~/99-custom.lst:/etc/snidust/domains.d/99-custom.lst:ro'
        image: 'ghcr.io/seji64/snidust:main'
```

### Spoof all domains

If you don't want to maintain a list of domains and you just want to spoof everything set `SPOOF_ALL_DOMAINS` to `true`
**WARNING:**: As a result, the COMPLETE traffic runs through your VPS - this is not the optimal use of SniDust. Only the traffic needed to cloak the GeoLocation should flow through SniDust

```yaml
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - 'ALLOWED_CLIENTS=127.0.0.1, 10.111.123.7'
            - EXTERNAL_IP=10.111.123.8
            - SPOOF_ALL_DOMAINS=true
...
```

### Reload allowed clients without container restart

In case you want to have dynamic ALLOWED_CLIENTS ACL change your docker compose file to this:

```yaml
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - 'ALLOWED_CLIENTS_FILE=/tmp/myacls.acl'
            - EXTERNAL_IP=10.111.123.8
        ports:
            - '443:443'
            - '80:80'
            - '53:5300/udp'
        volumes:
            - '~/myacls.acl:/tmp/myacls.acl:ro'
        image: 'ghcr.io/seji64/snidust:main'
```

Then you can reload your ACLs by querying a specific DNS name:
```
# Assuming 10.11.123.8 is the IP of your Server where snidust runs
dig @10.111.123.8 reload.acl.snidust.local
```

You should see in the logs (`docker logs snidust`) snidust has reloaded your ACLs

```
[SniDust] *** Reloading ACL... ***
...
[SniDust] *** ACL reload complete! ***
```

### Reload Domains without container restart

In case you added custom domains like the above, update the `99-custom.lst` file but don't want to restart your SniDust container each time, you can reload all domains with a custom DNS question.

```
# Assuming 10.11.123.8 is the IP of your Server where snidust runs
dig @10.111.123.8 reload.domainlist.snidust.local
```

You should see in the logs (`docker logs snidust`) snidust has reloaded your domain

```
[SniDust] Reloading domain lists...
...
[SniDust] *** End of Domain List ***
[SniDust] Domain Lists reloaded!
```

## Credits
Based on the following projects:

- https://dnsdist.org/
- https://github.com/mosajjal/sniproxy/
- https://github.com/andykimpe/wilmaa-proxy
- https://github.com/suuhm/unblock-proxy.sh
- https://github.com/ab77/netflix-proxy
