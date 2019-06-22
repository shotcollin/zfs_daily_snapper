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
  ssh "$localbackuphost" zfs get -r -pH -o name,value -t snapshot creation "$localbackuppath" | awk -f find_latest_snapshot.awk
}

local_find_latest_zfs_snapshots() {
  filteredZFSList="`filter_zfs_filesystem_list $zfsfilesystemslist`"
  completeSnapshotList="`zfs get -r -pH -o name,value -t snapshot creation | awk -f find_latest_snapshot.awk`"
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
local_latest_zfs_snapshot_list="`local_find_latest_zfs_snapshots`"

for zfs_filesystem_filtered_instance in `filter_zfs_filesystem_list "$zfsfilesystemslist"`
do \
  remote_fs_snapshot_filtered_instance="`echo "$remote_latest_zfs_snapshot_list" | grep -e "^${backuppath}/${zfs_filesystem_filtered_instance}@" | awk '{ print $1 }'`"
  remote_fs_snapshot_filtered_instance_snapshotname="`echo $remote_fs_snapshot_filtered_instance | awk -F'@' '{ print $2 }'`"
  local_fs_snapshot_filtered_instance="`echo "$local_latest_zfs_snapshot_list" | grep -e "^${zfs_filesystem_filtered_instance}@" | awk '{ print $1 }'`"
  local_fs_snapshot_filtered_instance_snapshotname="`echo $local_fs_snapshot_filtered_instance | awk -F'@' '{ print $2 }'`"
  if [ -n "$local_fs_snapshot_filtered_instance" ]
  then \
    if [ "$remote_fs_snapshot_filtered_instance_snapshotname" != "$local_fs_snapshot_filtered_instance_snapshotname" ]
    then \
      if [ -z "$remote_fs_snapshot_filtered_instance" ]
      then \
        echo "should create $local_fs_snapshot_filtered_instance on remote side"
      else \
        echo "should sync $local_fs_snapshot_filtered_instance on remote side with $remote_fs_snapshot_filtered_instance"
      fi
    fi
  fi
done
