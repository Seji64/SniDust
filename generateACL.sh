#!/bin/bash
CLIENTS=()
export DYNDNS_CRON_ENABLED=$false

if [ -n "${ALLOWED_CLIENTS_FILE}" ];
then
  if [ -f "${ALLOWED_CLIENTS_FILE}" ];
  then
    cat "$ALLOWED_CLIENTS_FILE" >> /etc/dnsdist/allowedClients.acl
  else
    echo "[ERROR] ALLOWED_CLIENTS_FILE is set but file does not exists or is not accessible!"
  fi
else
  IFS=', ' read -ra array <<< "$ALLOWED_CLIENTS"
  for i in ${array[@]}; do
    /usr/bin/ipcalc -cs $i
    retVal=$?
    if [ $retVal -eq 0 ]; then
      CLIENTS+=( ${i} )
    else
      RESOLVE_RESULT=$(/usr/bin/dog --short --type A ${i})
      retVal=$?
      if [ $retVal -eq 0 ]; then
        export DYNDNS_CRON_ENABLED=$true
        CLIENTS+=( ${RESOLVE_RESULT} )
      else
        echo "[ERROR] Could not resolve '${i}' => Skipping"
      fi
    fi
  done
  if [[ ! "${array[@]}" =~ '127.0.0.1' ]] && [[ "$DYNDNS_CRON_ENABLED" -eq $true ]]; then
    echo "[INFO] Adding '127.0.0.1' to allowed clients cause else cron reload will not work"
    CLIENTS+=( "127.0.0.1" )
  fi
  printf '%s\n' "${CLIENTS[@]}" > /etc/dnsdist/allowedClients.acl
fi

if [ -f "/etc/dnsdist/allowedClients.acl" ];
then
  while read -r line
  do
      echo "$line,allow" >> /etc/sniproxy/allowedClients.acl
  done < "/etc/dnsdist/allowedClients.acl"
fi