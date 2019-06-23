#!/bin/sh -x

scriptdirectory=`dirname $0`

while [ "$#" -gt 0 ]
do \
  case "$1" in
    "--host")   shift && [ "$#" -gt 0 ] && backuphost="$1";;
    "--path")   shift && [ "$#" -gt 0 ] && backuppath="$1";;
  esac
  shift
done

if cd `realpath $scriptdirectory`
then \
  ./zfs_daily_snapper.sh && ./zfs_daily_replica.sh --host "$backuphost" --path "$backuppath" && ./zfs_snap_gc.sh
fi