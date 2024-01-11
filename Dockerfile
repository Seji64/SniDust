FROM alpine:3.19
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

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD (pgrep "dnsdist" > /dev/null && pgrep "sniproxy" > /dev/null) || exit 1

# Expose Ports
EXPOSE 5300/udp
EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 8083/tcp

RUN echo "I'm building for $TARGETPLATFORM"

# Update Base
RUN apk update && apk upgrade

# Install needed packages and clean up
RUN apk add --no-cache tini dnsdist curl bash gnupg procps ca-certificates openssl dog lua5.4-filesystem ipcalc && rm -rf /var/cache/apk/*

# Setup Folder(s)
RUN mkdir -p /etc/dnsdist/conf.d && \
    mkdir -p /etc/snidust/ && \
    mkdir -p /etc/sniproxy/

# Download and install sniproxy
RUN ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "amd64"  ;; \
    "linux/arm/v7")  echo "arm"   ;; \
    "linux/arm64")   echo "arm64" ;; \
    *)               echo ""        ;; esac) \
  && echo "ARCH=$ARCH" \
  && curl -sSL https://github.com/mosajjal/sniproxy/releases/download/v2.0.4/sniproxy-v2.0.4-linux-${ARCH}.tar.gz | tar xvz \
  && chmod +x sniproxy && install sniproxy /usr/local/bin && rm sniproxy

# Copy Files
COPY configs/dnsdist/dnsdist.conf.template /etc/dnsdist/dnsdist.conf.template
COPY configs/dnsdist/conf.d/00-SniDust.conf /etc/dnsdist/conf.d/00-SniDust.conf
COPY domains.d /etc/snidust/domains.d
COPY configs/sniproxy/config.yaml /etc/sniproxy/config.yaml

COPY entrypoint.sh /entrypoint.sh
COPY generateACL.sh /generateACL.sh
COPY dynDNSCron.sh /dynDNSCron.sh
RUN chown -R dnsdist:dnsdist /etc/dnsdist/ && \
    chmod +x /entrypoint.sh && \
    chmod +x /generateACL.sh && \
    chmod +x dynDNSCron.sh

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/bash", "/entrypoint.sh"]