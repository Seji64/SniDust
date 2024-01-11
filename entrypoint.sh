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

echo "[INFO] Generating ACL..."
set +e
source generateACL.sh
set -e


echo "[INFO] Generating DNSDist Configs..."
/bin/bash /etc/dnsdist/dnsdist.conf.template > /etc/dnsdist/dnsdist.conf

if [ -z "${DYNDNS_CRON_ENABLED}" ];
then
  echo "[INFO] DynDNS Address in ALLOWED_CLIENTS detected => Enable cron job"
  echo "$DNYDNS_CRON_SCHEDULE /bin/bash /dynDNSCron.sh" > /etc/crontabs/root
  crond -f &
fi

echo "[INFO] Starting DNSDist..."
chown -R dnsdist:dnsdist /etc/dnsdist/
/usr/bin/dnsdist -C /etc/dnsdist/dnsdist.conf --supervised --disable-syslog --uid dnsdist --gid dnsdist &

echo "[INFO] Starting sniproxy"
(until /usr/local/bin/sniproxy --config "/etc/sniproxy/config.yaml"; do
    if [ -f "/tmp/reload_sni_proxy" ];
    then
      # ignore => restarted by cron
      rm -f /tmp/reload_sni_proxy
    else
      echo "[WARN] sniproxy crashed with exit code $?. Restarting..." >&2
    fi
    sleep 1
done) &
echo "[INFO] Using $EXTERNAL_IP - Point your DNS settings to this address"
wait -n
