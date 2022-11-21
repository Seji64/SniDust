FROM alpine:3.16
LABEL org.opencontainers.image.authors="seji@tihoda.de"

ENV DNSDIST_BIND_IP=0.0.0.0
ENV ALLOWED_CLIENTS=127.0.0.1
ENV EXTERNAL_IP=
ENV DNSDIST_WEBSERVER_PASSWORD=
ENV DNSDIST_WEBSERVER_API_KEY=
ENV DNSDIST_WEBSERVER_NETWORKS_ACL="127.0.0.1, ::1"
ENV DNSDIST_UPSTREAM_CHECK_INTERVAL=10

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD pgrep "dnsdist" > /dev/null || exit 1

# Expose Ports
EXPOSE 5300/udp
EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 8083/tcp

# Update Base
RUN apk update && apk upgrade

# Install needed packages and clean up
RUN apk add --no-cache tini dnsdist curl bash sed gnupg procps ca-certificates openssl dog lua5.3-filesystem && rm -rf /var/cache/apk/*

# Setup Folder(s)
RUN mkdir -p /etc/dnsdist/conf.d && \
    mkdir -p /etc/snidust/

# Download and install sniproxy
RUN ARCH=$(case ${TARGETPLATFORM:-linux/amd64} in \
    "linux/amd64")   echo "amd64"  ;; \
    "linux/arm/v7")  echo "arm"   ;; \
    "linux/arm64")   echo "arm64" ;; \
    *)               echo ""        ;; esac) \
  && echo "ARCH=$ARCH" \
  && curl -sSL https://github.com/mosajjal/sniproxy/releases/download/v0.9.0/sniproxy-v0.9.0-linux-${ARCH}.tar.gz | tar xvz \
  && chmod +x sniproxy

# Copy Files
COPY configs/dnsdist/dnsdist.conf /etc/dnsdist/dnsdist.conf
COPY configs/dnsdist/conf.d/SniDust.conf /etc/dnsdist/conf.d/SniDust.conf
COPY domains.d /etc/snidust/domains.d

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
