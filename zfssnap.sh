#!/bin/sh
#####
##### source: https://www.iceflatline.com/2020/02/a-simple-script-for-creating-and-deleting-rolling-zfs-snapshots-in-freebsd/
#####

### BEGIN INFO
# PROVIDE: 
# REQUIRE: 
# KEYWORD: 
# Description:	
# This script is used to create zfs snapshots and remove older snapshots. 
# The number of snapshots to retain is defined in the variable retention.
# Author: iceflatline <iceflatline@gmail.com>
#
# OPTIONS:
# -v: Be verbose
### END INFO

### START OF SCRIPT 
# These variables are named first because they are nested in other variables. 
snap_prefix=snap 
retention=90 

# Full paths to these utilities are needed when running the script from cron.
date=/bin/date
grep=/usr/bin/grep
sed=/usr/bin/sed
sort=/usr/bin/sort
xargs=/usr/bin/xargs
zfs=/sbin/zfs

src_0="pool_0/dataset_0"
today="$snap_prefix-`date +%Y%m%d%H%M`"
snap_today="$src_0@$today"
snap_old=`$zfs list -t snapshot -o name | $grep "$src_0@$snap_prefix*" | $sort -r | $sed 1,${retention}d | $xargs -n 1`
log=/home/iceflatline/cronlog

# Create a blank line between the previous log entry and this one.
echo >> $log

# Print the name of the script.
echo "zfssnap.sh" >> $log

# Print the current date/time.
$date >> $log

echo >> $log

# Look for today's snapshot and, if not found, create it.  
if $zfs list -H -o name -t snapshot | $grep "$snap_today" > /dev/null
then
	echo "Today's snapshot '$snap_today' already exists." >> $log
	# Uncomment if you want the script to exit when it does not create today's snapshot:
	#exit 1 
else
	echo "Taking today's snapshot: $snap_today" >> $log
	$zfs snapshot -r $snap_today >> $log 2>&1
fi

echo >> $log

# Remove snapshot(s) older than the value assigned to $retention.
echo "Attempting to destroy old snapshots..." >> $log

if [ -n "$snap_old" ]
then
	echo "Destroying the following old snapshots:" >> $log
	echo "$snap_old" >> $log
	$zfs list -t snapshot -o name | $grep "$src_0@$snap_prefix*" | $sort -r | $sed 1,${retention}d | $xargs -n 1 $zfs destroy -r >> $log 2>&1
else
    echo "Could not find any snapshots to destroy."	>> $log
fi

# Mark the end of the script with a delimiter.
echo "**********" >> $log
# END OF SCRIPT
