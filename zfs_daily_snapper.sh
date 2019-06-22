#!/bin/sh

show_what_you_done_first=0

while [ $# -ge 1 ]
do \
  case $1 in
    "--show") show_what_you_done_first=1;;
    "--debug") set -x;;
  esac
  shift
done

zfsfilesystemslist="`zfs list -o name -pH -t filesystem 2>/dev/null`"
todaysdatetimestamp=`date +%F`

filter_zfs_filesystem_list() {
  filterlist="tmp empty src ports"
  providedlist="$1"
  for filterinstance in $filterlist
  do \
    providedlist="`echo "$providedlist" | grep -ve "/${filterinstance}\$"`"
  done
  echo $providedlist
}

is_filesystem_having_todays_snapshot() {
  providedfilesystem="$1"
  filesystemsnapshotlist="`zfs list -o name -pH -t snapshot 2>/dev/null`"
  if echo "$filesystemsnapshotlist" | grep -e "^${providedfilesystem}@${todaysdatetimestamp}\$" >/dev/null
  then \
    return 0
  else \
    return 1
  fi
}

for zfs_filesystem_filtered_instance in `filter_zfs_filesystem_list "$zfsfilesystemslist"`
do \
  if is_filesystem_having_todays_snapshot $zfs_filesystem_filtered_instance
  then \
    echo "$zfs_filesystem_filtered_instance already has todays snapshot!" >&2
  else \
    filteredzfsfilesystemslist=`echo -e "${filteredzfsfilesystemslist}\n${zfs_filesystem_filtered_instance}"`
  fi
done

if [ $show_what_you_done_first -eq 1 ]
then \
  echo "Will snapshot these filesystems:"
  echo "$filteredzfsfilesystemslist"
  echo " does it seem OK?"
  read answer
  if [ "$answer" = "yes" ]
  then \
    proceed=1
  fi
fi

if [ $show_what_you_done_first -eq 1 ] && [ $proceed -eq 1 ]
then \
  for zfs_filesystem_filtered_instance in $filteredzfsfilesystemslist
  do \
    zfs snapshot "${zfs_filesystem_filtered_instance}@${todaysdatetimestamp}"
  done
fi