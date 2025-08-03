##!/bin/bash
CLIENTS=()
export DYNDNS_CRON_ENABLED=false

function read_acl () {
  for i in "${client_list[@]}"
  do
    cleaned_i=$(echo "$i" | tr -d '\r')
    /usr/bin/ipcalc -cs "$cleaned_i"
    retVal=$?
    if [ $retVal -eq 0 ]; then
      CLIENTS+=( "${cleaned_i}" )
    else
      RESOLVE_RESULT=$(/usr/bin/dog --json "$cleaned_i" | jq -r '.responses[].answers | map(select(.type == "A")) | first | .address')
      retVal=$?
      if [ $retVal -eq 0 ]; then
        export DYNDNS_CRON_ENABLED=true
        CLIENTS+=( "${RESOLVE_RESULT}" )
      else
        echo "[ERROR] Could not resolve '${cleaned_i}' => Skipping"
      fi
    fi
  done
  (echo "${client_list[@]}" | grep -q '127.0.0.1')
  localipCheck=$?
  if [[ "$localipCheck" -eq 1 ]] && [[ "$DYNDNS_CRON_ENABLED" = true ]]; then
    echo "[INFO] Adding '127.0.0.1' to allowed clients cause else cron reload will not work"
    CLIENTS+=( "127.0.0.1" )
  fi
}

client_list=()
if [ -n "${ALLOWED_CLIENTS_FILE}" ];
then
  echo "[INFO] Using ALLOWED_CLIENTS_FILE!"
  if [ -f "${ALLOWED_CLIENTS_FILE}" ];
  then
    echo "[INFO] Reading ACL from ${ALLOWED_CLIENTS_FILE}!"
    mapfile -t client_list < "$ALLOWED_CLIENTS_FILE"
    echo "${client_list}"
  else
    echo "[ERROR] ALLOWED_CLIENTS_FILE is set but file does not exists or is not accessible!"
  fi
else
  IFS=', ' read -ra client_list <<< "$ALLOWED_CLIENTS"
fi

read_acl
printf '%s\n' "${CLIENTS[@]}" > /etc/dnsdist/allowedClients.acl

if [ -f "/etc/dnsdist/allowedClients.acl" ];
then
  echo "" > etc/nginx/allowedClients.conf
  while read -r line
  do
    echo "allow $line;" >> /etc/nginx/allowedClients.conf
  done < "/etc/dnsdist/allowedClients.acl"
  echo "deny  all;" >> /etc/nginx/allowedClients.conf
else
  touch /etc/nginx/allowedClients.conf
fi
