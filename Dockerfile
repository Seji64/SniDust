FROM alpine:3.20
LABEL org.opencontainers.image.authors="seji@tihoda.de"
ARG TARGETPLATFORM

ENV DNSDIST_BIND_IP=0.0.0.0
ENV ALLOWED_CLIENTS=127.0.0.1
ENV ALLOWED_CLIENTS_FILE=
ENV EXTERNAL_IP=
ENV DNSDIST_WEBSERVER_PASSWORD=
ENV DNSDIST_WEBSERVER_API_KEY=
ENV DNSDIST_WEBSERVER_NETWORKS_ACL="127.0.0.1, ::1"
ENV DNSDIST_UPSTREAM_CHECK_INTERVAL=10
ENV DNSDIST_UPSTREAM_POOL_NAME="upstream"
ENV DNSDIST_RATE_LIMIT_DISABLE=false
ENV DNSDIST_RATE_LIMIT_WARN=800
ENV DNSDIST_RATE_LIMIT_BLOCK=1000
ENV DNSDIST_RATE_LIMIT_BLOCK_DURATION=360
ENV DNSDIST_RATE_LIMIT_EVAL_WINDOW=60
ENV SPOOF_ALL_DOMAINS=false
ENV DNYDNS_CRON_SCHEDULE="*/15 * * * *"
ENV INSTALL_DEFAULT_DOMAINS=true

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD (pgrep "dnsdist" > /dev/null && pgrep "nginx" > /dev/null) || exit 1

# Expose Ports
EXPOSE 5300/udp
EXPOSE 8080/tcp
EXPOSE 8443/tcp
EXPOSE 8083/tcp

RUN echo "I'm building for $TARGETPLATFORM"

# Update Base
RUN apk update && apk upgrade

# Create Users
RUN addgroup snidust && adduser -D -H -G snidust snidust

# Install needed packages and clean up
RUN apk add --no-cache tini dnsdist curl bash gnupg procps ca-certificates openssl dog lua5.4-filesystem ipcalc libcap nginx nginx-mod-stream supercronic && rm -rf /var/cache/apk/*

# Setup Folder(s)
RUN mkdir -p /etc/dnsdist/conf.d && \
    mkdir -p /etc/snidust/domains.d && \
    mkdir -p /etc/sniproxy/ && \
    mkdir -p /var/lib/snidust/domains.d

# Copy Files
COPY configs/dnsdist/dnsdist.conf.template /etc/dnsdist/dnsdist.conf.template
COPY configs/dnsdist/conf.d/00-SniDust.conf /etc/dnsdist/conf.d/00-SniDust.conf
COPY configs/nginx/nginx.conf /etc/nginx/nginx.conf
COPY domains.d /var/lib/snidust/domains.d

COPY entrypoint.sh /entrypoint.sh
COPY generateACL.sh /generateACL.sh
COPY dynDNSCron.sh /dynDNSCron.sh

RUN chown -R snidust:snidust /etc/dnsdist/ && \
    chown -R snidust:snidust /etc/snidust/ && \
    chown -R snidust:snidust /etc/nginx/ && \
    chown -R snidust:snidust /var/log/nginx/ && \
    chown -R snidust:snidust /var/lib/nginx/ && \
    chown -R snidust:snidust /run/nginx/ && \
    chmod +x /entrypoint.sh && \
    chmod +x /generateACL.sh && \
    chmod +x dynDNSCron.sh

USER snidust

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]