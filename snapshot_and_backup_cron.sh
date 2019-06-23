#!/bin/sh -x

scriptdirectory=`dirname $0`

if cd `realpath $scriptdirectory`
then \
  ./zfs_daily_snapper.sh && ./zfs_daily_replica.sh && ./zfs_snap_gc.sh
fi