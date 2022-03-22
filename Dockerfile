FROM debian:11-slim
MAINTAINER Seji64 <seji@tihoda.de>

ENV DEBIAN_FRONTEND="noninteractive"
ENV DNSDIST_BIND_IP=0.0.0.0
ENV ALLOWED_CLIENTS=127.0.0.1
ENV EXTERNAL_IP=

# Expose Ports
EXPOSE 5300/udp
EXPOSE 80/tcp
EXPOSE 443/tcp

# Update Base and install sniproxy and dnsdist
RUN apt-get update && \
apt-get -y install sniproxy sed curl gnupg tini

COPY pdns.list /etc/apt/sources.list.d/pdns.list
COPY dnsdist_preference /etc/apt/preferences.d/dnsdist

RUN curl -sL https://repo.powerdns.com/FD380FBB-pub.asc | apt-key add - && \
apt-get update && apt-get -y install dnsdist && \
apt-get dist-upgrade && \
apt-get clean && \
rm -rf \
/tmp/* \
/var/lib/apt/lists/* \
/var/tmp/*

# Copy Configs
COPY configs/dnsdist/dnsdist.conf /etc/dnsdist/dnsdist.conf
COPY configs/dnsdist/conf.d/SniDust.conf /etc/dnsdist/conf.d/SniDust.conf
COPY configs/sniproxy/sniproxy.conf /etc/sniproxy.conf
COPY domains.lst /tmp/domains.lst

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]
