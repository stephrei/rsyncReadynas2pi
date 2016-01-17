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
# 14	SRCPATH and/or DSTPATH not writeable
# 16	LOG and/or RSYNC_LOG not writeable
# 18	script must be run as root
# 30	rsync errors


#TODO: 
#rsync progress indicator with --info=progress2 

PATH=$PATH"/root/bin/rsyncReadynas2pi"
source rsyncReadynas2pi_funcs.sh

### vars ###

SRCPATH=""
DSTPATH=""
DRY=""
LOCK="$0.lck"
LOG="$0.log"
RSYNC_LOG="$0.rsync.log"
EMAIL="awaynothere11@gmail.com"
ERROR_NO=""
MAILER=$(/usr/bin/which mail)


### main ###

trap trap_received SIGHUP SIGINT SIGTERM
SRCPATH="$1"; DSTPATH="$2"; [[ "$3" ]] && DRY="n" || DRY=""
preliminary_checks
mark_log_start

# write params / commands to log file
write2log "SRCPATH = $SRCPATH"
write2log "DSTPATH = $DSTPATH"

write2log "DRY = $DRY"
write2log "RSYNC_LOG = $RSYNC_LOG"
write2log "LOG = $LOG"
write2log "executing command: rsync -ratz$DRY --delete --exclude='lost+found' --exclude='*.Apple*' --exclude='*.DS_*' --log-file=$RSYNC_LOG $SRCPATH $DSTPATH"

set_lockfile

# run rsync
write2log "clearing $RSYNC_LOG ..."
/bin/echo "" > "$RSYNC_LOG"
write2log "starting rsync ..."
email_progress "0" "starting rsync on $HOSTNAME"
rsync -ratz"$DRY" --delete --exclude="lost+found" --exclude="*.Apple*" --exclude="*.DS_*" --log-file="$RSYNC_LOG" "$SRCPATH" "$DSTPATH" && write2log "... finished rsync"
email_progress "100" "finished rsync on $HOSTNAME"

# email possible rsync errors - error no 30
if [ $(grep 'rsync error' $RSYNC_LOG | wc -l) -gt "0" ]; then 
	email_error "$(grep 'rsync error' $RSYNC_LOG)" "30"
fi

remove_lockfile
mark_log_end


