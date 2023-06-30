#!/bin/bash -e
if [ -z "${EXTERNAL_IP}" ];
then
  echo "External IP not set - trying to get IP by myself"
  EXTERNAL_IP=$(curl -f icanhazip.com)
  export EXTERNAL_IP
fi

if [ -z "${DNSDIST_WEBSERVER_PASSWORD}" ];
then
  echo "Dnsdist webserver password not set - generating one"
  DNSDIST_WEBSERVER_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12)
  export DNSDIST_WEBSERVER_PASSWORD
  echo "Generated WebServer Password: $DNSDIST_WEBSERVER_PASSWORD"
fi

if [ -z "${DNSDIST_WEBSERVER_API_KEY}" ];
then
  echo "Dnsdist webserver api key not set - generating one"
  DNSDIST_WEBSERVER_API_KEY=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
  export DNSDIST_WEBSERVER_API_KEY
  echo "Generated WebServer API Key: $DNSDIST_WEBSERVER_API_KEY"
fi

if [ -n "${ALLOWED_CLIENTS_FILE}" ];
then
  if [ -f "${ALLOWED_CLIENTS_FILE}" ];
  then
    ln -s "$ALLOWED_CLIENTS_FILE" /etc/dnsdist/allowedClients.acl
  else
    echo "[ERROR] ALLOWED_CLIENTS_FILE is set but file does not exists or is not accessible!"
  fi
else
  IFS=', ' read -ra array <<< "$ALLOWED_CLIENTS"
  printf '%s\n' "${array[@]}" > /etc/dnsdist/allowedClients.acl
fi

if [ -f "/etc/dnsdist/allowedClients.acl" ];
then
  while IFS= read -r line
  do
    echo "$line,allow" >> /etc/sniproxy/allowedClients.acl
  done < "/etc/dnsdist/allowedClients.acl"
fi

echo "Generating DNSDist Configs..."
/bin/bash /etc/dnsdist/dnsdist.conf.template > /etc/dnsdist/dnsdist.conf

echo "Starting DNSDist..."
chown -R dnsdist:dnsdist /etc/dnsdist/
/usr/bin/dnsdist -C /etc/dnsdist/dnsdist.conf --supervised --disable-syslog --uid dnsdist --gid dnsdist &

echo "Starting sniproxy"
/usr/local/bin/sniproxy --config "/etc/sniproxy/config.yaml" &
echo "[INFO] Using $EXTERNAL_IP - Point your DNS settings to this address"
wait -n
