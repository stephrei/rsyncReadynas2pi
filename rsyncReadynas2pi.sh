#!/bin/bash

# rsyncReadynas2pi.sh
# script rsyncs files from readynas to either cinnamon or caraway (RPi's)
# usage: rsyncReadynas2pi.sh <src_path> <dst_path> <|dry>
# awaynothere@hotmail.com 11jan16
# version 1.0

#TODO: 
# trap to remove lock file
# trap to add comment to log file about unnatural exit
# number errors and email errors


### vars ###

SRCPATH=DSTPATH=DRY=""
LOCK="/root/bin/$0.lck"
LOG="/root/bin/$0.log"
RSYNC_LOG="/root/bin/$0.rsync.log"


### functions ###

function display_usage() {


	USAGE="Usage: $0 <src_path> <dst_path> <|dry>"

	if [ "$#" == "0" ]; then
    		echo "$USAGE"
		echo "for example: $0 /mnt/readynas/pics cinnamon:/mnt/md1_data_2TB/"
		echo "for example: $0 /mnt/readynas/movies caraway:/mnt/md0_data_1TB/ dry for testing only (dry)"
    		exit 1
	fi
}

function write2log() {
	echo -n date "+%d%b %T" >> $LOG
	echo "$1" >> $LOG
}


### main ###

# rsync still running, eg. from yesterday? - check for lock file
if [ -f "$LOCK" ]; then
	echo; echo "Lock file exists at $LOCK, this normally means $0 is still running (check with ps aux). "
	echo "If the lock file was not correctly removed after the last exit remove it manually."
	write2log "lock file found at $LOCK, exiting ..."
	exit 1
fi

# correct arguments supplied?
if [ "$#" == "2" -o "$#" == "3" ]; then
	SRCPATH="$1"; DSTPATH="$2"; DRY="$3"
     	echo; echo "will rsync files from $SRCPATH to $DSTPATH"
		[[ "$DRY" ]] && echo " doing a test run only (dry)"
else
	echo; echo "Incorrect number of arguments!"
	display_usage
fi

# test that SRC, DST, LOG param are set
[[ -w "$RSYNC_LOG" ]] || (email_error && exit 1)

# write params / commands to log file
write2log "SRCPATH=$SRCPATH / DSTPATH=$DSTPATH / RSYNC_LOG=$RSYNC_LOG / DRY=$DRY"
write2log 'executing command: rsync -ratzv"$DRY" --exclude='lost+found' --exclude="*.Apple*" --exclude="*.DS_*" --log-file="$RSYNC_LOG" "$SRCPATH" "$DSTPATH"'

# run rsync
rsync -ratzv"$DRY" --exclude='lost+found' --exclude="*.Apple*" --exclude="*.DS_*" --log-file="$RSYNC_LOG" "$SRCPATH" "$DSTPATH"




# remove lock file
# set traps to remove lock file if aborted
 
