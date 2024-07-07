#!/bin/bash -e
if [ -z "${EXTERNAL_IP}" ];
then
  echo "[INFO] External IP not set - trying to get IP by myself"
  EXTERNAL_IP=$(curl -f icanhazip.com)
  export EXTERNAL_IP
fi

if [ -z "${DNSDIST_WEBSERVER_PASSWORD}" ];
then
  echo "[INFO] Dnsdist webserver password not set - generating one"
  DNSDIST_WEBSERVER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
  export DNSDIST_WEBSERVER_PASSWORD
  echo "[INFO] Generated WebServer Password: $DNSDIST_WEBSERVER_PASSWORD"
fi

if [ -z "${DNSDIST_WEBSERVER_API_KEY}" ];
then
  echo "[INFO] Dnsdist webserver api key not set - generating one"
  DNSDIST_WEBSERVER_API_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
  export DNSDIST_WEBSERVER_API_KEY
  echo "[INFO] Generated WebServer API Key: $DNSDIST_WEBSERVER_API_KEY"
fi

if [ "$INSTALL_DEFAULT_DOMAINS" = true ];
then
  echo "[INFO] Installing default domains..."
  cp -v /var/lib/snidust/domains.d/*.lst /etc/snidust/domains.d/
fi

echo "[INFO] Generating ACL..."
set +e
source generateACL.sh
set -e


echo "[INFO] Generating DNSDist Config..."
/bin/bash /etc/dnsdist/dnsdist.conf.template > /etc/dnsdist/dnsdist.conf

if [ "$DYNDNS_CRON_ENABLED" = true ];
then
  echo "[INFO] DynDNS Address in ALLOWED_CLIENTS detected => Enable cron job"
  echo "$DYNDNS_CRON_SCHEDULE /bin/bash /dynDNSCron.sh" > /etc/snidust/dyndns.cron
  supercronic /etc/snidust/dyndns.cron &
fi

echo "[INFO] Starting DNSDist..."
/usr/bin/dnsdist -C /etc/dnsdist/dnsdist.conf --supervised --disable-syslog --uid snidust --gid snidust &


echo "[INFO] Starting nginx.."
nginx
nginx_processId=$!

sleep 5

echo "==================================================================="
echo "[INFO] SniDust started => Using $EXTERNAL_IP - Point your DNS settings to this address"
echo "==================================================================="
wait $nginx_processId