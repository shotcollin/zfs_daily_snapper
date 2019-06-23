#!/bin/sh -x

scriptdirectory=`dirname $0`

while [ "$#" -gt 0 ]
do \
  case "$1" in
    "--host")   shift && [ "$#" -gt 0 ] && backuphost="$1";;
    "--path")   shift && [ "$#" -gt 0 ] && backuppath="$1";;
    "--nowait") nowaitforamoment="1";;
  esac
  shift
done

if cd `realpath $scriptdirectory`
then \
  if [ -z "$nowaitforamoment" ]
  then \
    randomnumber=`openssl rand -hex 12 | tr -d '[a-f]'`
    [ -z "$randomnumber" ] && randomnumber="1200" || [ "$randomnumber" -lt 600 ] && randomnumber=`expr $randomnumber + 600`
    waitseconds=`expr $randomnumber \% 3600`
    sleep $waitseconds
  fi
  ./zfs_daily_snapper.sh && ./zfs_daily_replica.sh --host "$backuphost" --path "$backuppath" && ./zfs_snap_gc.sh
fi