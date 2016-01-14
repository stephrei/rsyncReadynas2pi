#!/bin/bash

# rsyncReadynas2pi.sh
# script rsyncs files from readynas to either cinnamon or caraway (RPi's)
# general logs are kept at $LOG, rsync logs are kept at $RSYNC_LOG
# USAGE: rsyncReadynas2pi.sh <src_path> <dst_path> <|dry>
# awaynothere@hotmail.com 11jan16
# version 1.0
#
# list of errors
# no	description
# 10	lock file exists	
# 12	incorrect no of parameters	
# 14	SRC and/or DST not writeable
# 16	LOG and/or RSYNC_LOG not writeable
# 30	rsync errors


#TODO: 
#rsync progress indicator with --info=progress2 

### vars ###

SRCPATH=DSTPATH=DRY=""
LOCK="/root/bin/$0.lck"
LOG="/root/bin/$0.log"
RSYNC_LOG="/root/bin/$0.rsync.log"
EMAIL="awaynothere11@gmail.com"
ERROR_NO=""
MAILER=$(which mail)


### functions ###

function display_usage() {
# function not in use, script is intended to be used with cron job
	USAGE="Usage: $0 <src_path> <dst_path> <|dry>"

	if [ "$#" == "0" ]; then
		echo
    		echo "$USAGE"
		echo "for example: $0 /mnt/readynas/pics cinnamon:/mnt/md1_data_2TB/"
		echo "for example: $0 /mnt/readynas/movies caraway:/mnt/md0_data_1TB/ dry for testing only (dry)"
		echo
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
	echo $MSG | $MAILER -s "Error $ERROR_NO with rsync scripts on $HOSTNAME at $(date "+%d%b %T") hrs" $EMAIL
	write2log "emailed $MSG as error $ERROR_NO"
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

function check_root() {
	if [ "$UID" -ne "0" ]; then
		local $ERROR_NO="18"
		email_error "$0 must be run as root, exiting ..." $ERROR_NO
		write2log "emailed $0 was not run as root as error no $ERROR_NO"
                exit 1
	fi	
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
	email_error "Error rsyncing on $HOSTNAME: incorrect number of parameters supplied" "12"
	write2log 'Incorrect parameters supplied: SRCPATH="$1"; DSTPATH="$2"; DRY="$3"'
	write2log "exiting ..."
	exit 1
fi

# email working?
if [ $# != "0" ]; then
	write2log "mailer return non-zero exit status, exiting ..."
	remove_lockfile
	exit 1
fi

# are SRC, DST set and LOG, RSYNC_LOG writeable?
if [ "$SRC" == "" -o "$DST" == "" ]; then 
	email_error "Error rsyncing on $HOSTAME: SRC and/or DST not writeable" "14"
	write2log "SRC and/or DST not set, exiting ..."
	exit 1
else if [[ ! -f "$LOG" || ! -f "$RSYNC_LOG" ]]; then 
	email_error "Error rsyncing on $HOSTNAME: LOG and/or RSYNC_LOG not writeable" "16"
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

# email possible rsync errors - error no 30
email_error "$(grep 'rsync error' $RSYNC_LOG)" "30"

remove_lockfile
