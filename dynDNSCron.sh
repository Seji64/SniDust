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


echo "[INFO] [DnyDNSCron] reloading nginx..."
/usr/sbin/nginx -s reload
echo "[INFO] [DnyDNSCron] ngix successfully reloaded"