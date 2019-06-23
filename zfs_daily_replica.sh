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

remote_find_zfs_datasets() {
  localbackuphost="$1"
  localbackuppath="$2"
  ssh "$localbackuphost" zfs list -r -pH -o name -t filesystem "$localbackuppath"
}

local_find_latest_zfs_snapshots() {
  filteredZFSList="$1"
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
remote_zfs_datasets_list="`remote_find_zfs_datasets "$backuphost" "$backuppath"`"
filtered_zfs_filesystem_list="`filter_zfs_filesystem_list "$zfsfilesystemslist"`"
local_latest_zfs_snapshot_list="`local_find_latest_zfs_snapshots "$filtered_zfs_filesystem_list" | awk -f sort_zfs_paths.awk`"

for local_latest_zfs_snapshot_list_instance in $local_latest_zfs_snapshot_list
do \
  local_latest_zfs_snapshot_list_instance_fs=`echo $local_latest_zfs_snapshot_list_instance | awk -F'@' '{ print $1 }'`
  if echo "$remote_latest_zfs_snapshot_list" | grep -e "^${backuppath}/${local_latest_zfs_snapshot_list_instance_fs}@" >/dev/null
  then \
    echo "$local_latest_zfs_snapshot_list_instance found on the remote side, continuing"
  else \
    echo "no $local_latest_zfs_snapshot_list_instance found on the remote side, creating"
    if echo $remote_zfs_datasets_list | grep -e "^${backuppath}/${local_latest_zfs_snapshot_list_instance_fs}$" >/dev/null
    then \
      true
    else \
      ssh "$backuphost" zfs create -p "${backuppath}/${local_latest_zfs_snapshot_list_instance_fs}"
    fi
    zfs send "$local_latest_zfs_snapshot_list_instance" | ssh "$backuphost" zfs receive -F "${backuppath}/${local_latest_zfs_snapshot_list_instance_fs}"
  fi
done
