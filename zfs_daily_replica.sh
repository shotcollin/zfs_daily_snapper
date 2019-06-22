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
  backuphost="$1"
  backuppath="$2"
  
  ssh "$backuphost" zfs get -r -pH -o name,value -t snapshot creation "$backuppath" | awk -f find_latest_snapshot.awk

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

for zfs_filesystem_filtered_instance in `filter_zfs_filesystem_list "$zfsfilesystemslist"`
do \

done