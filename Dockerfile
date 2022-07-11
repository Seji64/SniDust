FROM alpine:3.16
LABEL org.opencontainers.image.authors="seji@tihoda.de"

ENV DNSDIST_BIND_IP=0.0.0.0
ENV ALLOWED_CLIENTS=127.0.0.1
ENV EXTERNAL_IP=
ENV DNSDIST_WEBSERVER_PASSWORD=
ENV DNSDIST_WEBSERVER_API_KEY=
ENV DNSDIST_WEBSERVER_NETWORKS_ACL="127.0.0.1, ::1"

# HEALTHCHECKS
HEALTHCHECK --interval=30s --timeout=3s CMD pgrep "dnsdist" > /dev/null || exit 1

# Expose Ports
EXPOSE 5300/udp
EXPOSE 80/tcp
EXPOSE 443/tcp
EXPOSE 8083/tcp

# Update Base and install sniproxy and dnsdist
RUN apk update && apk upgrade  && \
apk add --no-cache sniproxy dnsdist sed curl gnupg tini procps bash && \
mkdir -p /etc/dnsdist/conf.d &&  \
rm -rf /var/cache/apk/* && \
rm -rf /var/tmp/*

# Copy Configs
COPY configs/dnsdist/dnsdist.conf /etc/dnsdist/dnsdist.conf
COPY configs/dnsdist/conf.d/SniDust.conf /etc/dnsdist/conf.d/SniDust.conf
COPY configs/sniproxy/sniproxy.conf /etc/sniproxy.conf
COPY domains.lst /tmp/domains.lst

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
