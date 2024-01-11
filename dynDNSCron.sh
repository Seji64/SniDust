#!/bin/bash
echo "[INFO] [DnyDNSCron] Regenerating ACL.."
source /generateACL.sh
echo "[INFO] [DnyDNSCron] ACL regenerated!"
echo "[INFO] [DnyDNSCron] Reloading DnsDist ACl config"
/usr/bin/dog @127.0.0.1:5300 --short reload.acl.snidust.local
retVal=$?
if [ $retVal -eq 0 ]; then
  echo "[INFO] [DnyDNSCron] DnsDist ACL config successfully reloaded!"
else
  echo "[ERROR] [DnyDNSCron] Failed to reload DnsDist ACL config!"
fi

touch /tmp/reload_sni_proxy
echo "[INFO] [DnyDNSCron] Reloading/Restarting Sniproxy..."
PID_SNIPROXY=$(pidof sniproxy)
kill -HUP $PID_SNIPROXY
echo "[INFO] [DnyDNSCron] Sniproxy successfully reloaded/restarted"