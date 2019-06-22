#!/bin/sh -x

zfsfilesystemslist="`zfs list -o name -pH -t filesystem 2>/dev/null`"
backuphost=""
backuppath=""

filter_zfs_filesystem_list() {
  filterlist="tmp empty src ports crash audit"
  providedlist="$1"
  for filterinstance in $filterlist
  do \
    providedlist="`echo "$providedlist" | grep -ve "/${filterinstance}\$"`"
  done
  for zfsinstance in $providedlist
  do \
    if zfs get -o value -pH mountpoint "$zfsinstance" | grep -e "^none\$" >/dev/null || zfs get -o value -pH canmount "$zfsinstance" | grep -e "^off\$" >/dev/null
    then \
      providedlist="`echo "$providedlist" | grep -ve "^${zfsinstance}\$"`"
    fi
  done
  echo $providedlist
}

remote_find_latest_zfs_snapshots() {
  localbackuphost="$1"
  localbackuppath="$2"
  ssh "$localbackuphost" zfs get -r -pH -o name,value -t snapshot creation "$localbackuppath" | awk -f find_latest_snapshot.awk | awk '{ print $1 }'
}

local_find_latest_zfs_snapshots() {
  filteredZFSList="`filter_zfs_filesystem_list "$1"`"
  completeSnapshotList="`zfs get -r -pH -o name,value -t snapshot creation | awk -f find_latest_snapshot.awk | awk '{ print $1 }'`"
  for filteredZFSListInstance in $filteredZFSList
  do \
    echo "$completeSnapshotList" | grep -e "^${filteredZFSListInstance}@"
  done
}

while [ "$#" -gt 0 ]
do \
  case "$1" in
    "--host")   shift && [ "$#" -gt 0 ] && backuphost="$1";;
    "--path")   shift && [ "$#" -gt 0 ] && backuppath="$1";;
  esac
  shift
done

if [ -z "$backuphost" ] || [ -z "$backuppath" ]
then \
  echo "backuphost and/or backuppath not set, exiting"
  exit 1
fi

remote_latest_zfs_snapshot_list="`remote_find_latest_zfs_snapshots "$backuphost" "$backuppath"`"
local_latest_zfs_snapshot_list="`local_find_latest_zfs_snapshots "$zfsfilesystemslist"`"

for local_latest_zfs_snapshot_list_instance in $local_latest_zfs_snapshot_list
do \
  local_latest_zfs_snapshot_list_instance_fs=`echo $local_latest_zfs_snapshot_list_instance | awk -F'@' '{ print $1 }'`
  if echo $remote_latest_zfs_snapshot_list | grep -e "^${local_latest_zfs_snapshot_list_instance_fs}@" >/dev/null
  then \
    echo "would create $local_latest_zfs_snapshot_list_instance on the remote side"
  fi
done
