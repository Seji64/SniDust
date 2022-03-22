# SniDust
SmartDNS Proxy to hide your GeoLocation. Based on DnsDist and SniProxy

# Supported Services

- Zattoo
- Wilmaa
- Netflix
- Hulu
- Amazon Prime
- ...and many more (see [domains.lst](domains.lst))

# Example Usage

```
docker run -d -e ALLOWED_CLIENTS="127.0.0.1, PUBLIC_ISP_IP" -e EXTERNAL_IP=PUBLIC_VPS_IP -p 443:443 -p 80:80 -p 53:5300/udp ghcr.io/seji64/snidust:main
```

Point your DNS Settings to PUBLIC_VPS_IP and watch your favorite show

# Credits
Based on the following projects:

- https://github.com/andykimpe/wilmaa-proxy
- https://github.com/suuhm/unblock-proxy.sh
- https://github.com/ab77/netflix-proxy
