[![Docker](https://github.com/Seji64/SniDust/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Seji64/SniDust/actions/workflows/docker-publish.yml)

# SniDust
SmartDNS Proxy to hide your GeoLocation. Based on DnsDist and SniProxy

## Supported Services

- Zattoo
- Wilmaa
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
For this **example** i we assume your public ip (of your *client*) is `10.111.123.7`

### Get your IP of your Server

```
curl https://ifconfig.me
```
For this **example** i we assume your public ip (of your *server*) is `10.111.123.8`

### Run SniDust on your Server

```
docker run -d --name snidust -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7" -e EXTERNAL_IP=10.111.123.8 -p 443:443 -p 80:80 -p 53:5300/udp ghcr.io/seji64/snidust:main
```

Or if you use docker-compose:

```
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - ALLOWED_CLIENTS: '127.0.0.1, 10.111.123.7'
            - EXTERNAL_IP: '10.111.123.8'
            - SPOOF_ALL_DOMAINS: 'false' # Set to true (case sensetive!) if you want spoof ALL domains.
        ports:
            - '443:443'
            - '80:80'
            - '53:5300/udp'
        image: 'ghcr.io/seji64/snidust:main'
```

### Check logs of the container
```
docke logs snidust
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

Change your network settings and set as DNS Server 10.111.123.8 (PUBLIC_VPS_IP)

Your GeoLaction should now hidden :-)

## Troubleshooting

### Error Port 53 is already in use

In this case you either run another service (like Pi-Hole) which already uses this Port or you likely use an linux distribution which uses systemd.

In case systemd is already using port 53 you can follow this [Guide](https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html) to free up this port.

## Advanced

### Add custom domains

In case you want to add custom domains which not included by default, this can be done easily.
Create a file with the name `99-custom.lst`. Insert all your custom domains in this file.

#### Mount it

```
docker run --name snidust -e ALLOWED_CLIENTS="127.0.0.1, 10.111.123.7" -e EXTERNAL_IP=10.111.123.8 -p 443:443 -p 80:80 -p 53:5300/udp -v ~/99-custom.lst:/etc/snidust/domains.d/99-custom.lst:ro ghcr.io/seji64/snidust:main
```

Or if you use docker-compose:

```
version: '3.3'
services:
    snidust:
        container_name: snidust
        environment:
            - ALLOWED_CLIENTS: '127.0.0.1, 10.111.123.7'
            - EXTERNAL_IP: 10.111.123.8
        ports:
            - '443:443'
            - '80:80'
            - '53:5300/udp'
        volumes:
            - '~/99-custom.lst:/etc/snidust/domains.d/99-custom.lst:ro'
        image: 'ghcr.io/seji64/snidust:main'
```

## Reload Domains without container restart

In case you added custom domains like above, updates the `99-custom.lst` file but don't want to restart your SniDust container each time, you can reload all domains with a custom dns question.

```
# assuming 10.11.123.8 is your ip of your Server where snidust runs
dig @10.111.123.8 reload.domainlist.snidust.local
```

You should see in the logs (`docker logs snidust`) snidust has reloaded your domain

```
[SniDust] Reloading domain lists..
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
