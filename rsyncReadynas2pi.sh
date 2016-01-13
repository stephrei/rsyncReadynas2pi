#!/bin/bash

# rsyncReadynas2pi.sh
# script rsyncs files from readynas to either cinnamon or caraway (RPi's)
# general logs are kept at $LOG, rsync logs are kept at $RSYNC_LOG
# usage: rsyncReadynas2pi.sh <src_path> <dst_path> <|dry>
# awaynothere@hotmail.com 11jan16
# version 1.0

#TODO: 
#rsync progress 
#grep and email for rsync errors

### vars ###

SRCPATH=DSTPATH=DRY=""
LOCK="/root/bin/$0.lck"
LOG="/root/bin/$0.log"
RSYNC_LOG="/root/bin/$0.rsync.log"
EMAIL="awaynothere11@gmail.com"
ERROR_NO=""


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

function email_error() {
	local MSG="$1"
	local ERROR_NO="${2:-"Unknown Error"}"	
	echo $MSG | $MAILER -s "Error no $ERROR_NO with rsync scripts on $HOSTNAME at $(date "+%d%b %T") hrs" $EMAIL
}

function email_progress() {
	local PROGRESS="$1"
	local MSG="$2"
	echo "$MSG" | $MAILER -s "Rsyncing on $HOSTNAME: progress = $PROGRESS%" $EMAIL
}

function set_lockfile() {
	write2log "setting lock file"
	touch $LOCK 
}

function remove_lockfile() {
	write2log "removing lock file"
	rm -f 2>/dev/null $LOCK
}


### main ###
trap remove_lockfile SIGHUP SIGINT SIGTERM EXIT

## preliminary checks
# rsync still running, eg. from yesterday? - check for lock file
if [ -f "$LOCK" ]; then
	email_error "Lock file exists at $LOCK, this normally means $0 is still running (check with ps aux). If the lock file was not correctly removed after the last exit remove it manually. Check log files at $LOG for more details." "10"
	write2log "lock file found at $LOCK, exiting ..."
	exit 1
fi

# correct arguments supplied?
if [ "$#" == "2" -o "$#" == "3" ]; then
	SRCPATH="$1"; DSTPATH="$2"; DRY="$3"
else
	echo; echo "Incorrect number of arguments!"
	write2log 'Incorrect parameters supplied: SRCPATH="$1"; DSTPATH="$2"; DRY="$3"'
	write2log "exiting ..."
	display_usage
	exit 1
fi

# email working?
MAILER=$(which mail)
if [ $# != "0" ]; then
	write2log "mailer return non-zero exit status, exiting ..."
	remove_lockfile
	exit 1
fi

# are SRC, DST set and LOG, RSYNC_LOG writeable?
if [ "$SRC" == "" -o "$DST" == "" ]; then 
	write2log "SRC and/or DST not set, exiting ..."
	exit 1
else if [[ ! -f "$LOG" || ! -f "$RSYNC_LOG" ]]; then 
	write2log "LOG and/or RSYNC_LOG not writeable, exiting ..."
	exit 1
fi

# write params / commands to log file
write2log "SRCPATH=$SRCPATH / DSTPATH=$DSTPATH / RSYNC_LOG=$RSYNC_LOG / DRY=$DRY"
write2log 'executing command: rsync -ratzv"$DRY" --exclude='lost+found' --exclude="*.Apple*" --exclude="*.DS_*" --log-file="$RSYNC_LOG" "$SRCPATH" "$DSTPATH"'
set_lockfile

## run rsync
write2log "starting rsync ..."
email_progress "0" "starting rsync on $HOSTNAME"
rsync -ratzv"$DRY" --exclude='lost+found' --exclude="*.Apple*" --exclude="*.DS_*" --log-file="$RSYNC_LOG" "$SRCPATH" "$DSTPATH" && write2log "... finished rsync"
email_progress "100" "finished rsync on $HOSTNAME"

remove_lockfile
