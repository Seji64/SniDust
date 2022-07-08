#!/bin/bash -e
if [ -z ${EXTERNAL_IP} ];
then
  echo "External IP not set - trying to get IP by myself"
  export EXTERNAL_IP=$(curl icanhazip.com)
fi

if [ -z ${DNSDIST_WEBSERVER_PASSWORD} ];
then
  echo "Dnsdist webserver password not set - generating one"
  export DNSDIST_WEBSERVER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
  echo "Generated WebServer Password: $DNSDIST_WEBSERVER_PASSWORD"
fi

if [ -z ${DNSDIST_WEBSERVER_API_KEY} ];
then
  echo "Dnsdist webserver api key not set - generating one"
  export DNSDIST_WEBSERVER_API_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
  echo "Generated WebServer API Key: $DNSDIST_WEBSERVER_API_KEY"
fi

IFS=', ' read -ra array <<< "$ALLOWED_CLIENTS"
printf '%s\n' "${array[@]}" > /etc/dnsdist/allowedClients.acl


sed -i "s/DNSDIST_BIND_IP/$DNSDIST_BIND_IP/" /etc/dnsdist/dnsdist.conf && \
sed -i "s/EXTERNAL_IP/$EXTERNAL_IP/" /etc/dnsdist/dnsdist.conf && \
sed -i "s/DNSDIST_WEBSERVER_PASSWORD/$DNSDIST_WEBSERVER_PASSWORD/" /etc/dnsdist/dnsdist.conf && \
sed -i "s/DNSDIST_WEBSERVER_API_KEY/$DNSDIST_WEBSERVER_API_KEY/" /etc/dnsdist/dnsdist.conf && \
sed -i "s/DNSDIST_WEBSERVER_NETWORKS_ACL/$DNSDIST_WEBSERVER_NETWORKS_ACL/" /etc/dnsdist/dnsdist.conf && \
chown -R root:_dnsdist -R /etc/dnsdist

echo "Starting DNSDist..."
/usr/bin/dnsdist --supervised --disable-syslog --uid _dnsdist --gid _dnsdist &
echo "Starting sniproxy"
/usr/sbin/sniproxy -c /etc/sniproxy.conf -f &

echo "[INFO] Using $EXTERNAL_IP - Point your DNS settings to this address"

wait -n
