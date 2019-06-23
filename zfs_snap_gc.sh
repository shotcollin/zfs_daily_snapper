#!/bin/sh

# This script removes old ZFS snapshots that are older 
# than some time (should be run as cron job)


while [ $# -ge 1 ]
do \
  case $1 in
    "--debug") set -x;;
  esac
  shift
done

zfssnapshotslist="`zfs list -o name -pH -t snapshot 2>/dev/null`"
oldunixtimestamp=`date -jn -v -2m +%s`

for snapshotinstance in $zfssnapshotslist
do \
  if [ "`zfs get -pH -o value type $snapshotinstance`" = "snapshot" ]
  then \
    if [ "`zfs get -pH -o value creation $snapshotinstance`" -lt "$oldunixtimestamp" ]
    then \
      sudo zfs destroy "$snapshotinstance"
    fi
  fi
done
