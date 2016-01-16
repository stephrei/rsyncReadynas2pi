#!/bin/bash

# rsyncReadynas2pi_funcs.sh
# collection of functions used by script rsyncReadynas2pi
# awaynothere11@gmail.com

function display_usage() {
# function not in use, script is intended to be used with cron job
        USAGE="Usage: $0 <src_path> <dst_path> <|dry>"

        if [ "$#" == "0" ]; then
                /bin/echo
                /bin/echo "$USAGE"
                /bin/echo "for example: $0 /mnt/readynas/pics cinnamon:/mnt/md1_data_2TB/"
                /bin/echo "for example: $0 /mnt/readynas/movies caraway:/mnt/md0_data_1TB/ dry for testing only (dry)"
                /bin/echo
                exit 1
        fi
}

function check_root() {
        if [ "$UID" -ne "0" ]; then
                local ERROR_NO="18"
                email_error "$0 must be run as root, exiting ..." $ERROR_NO
                exit 1
        fi
}

function write2log() {
        if [ "$UID" -eq "0" ]; then
                /bin/echo -n $(/bin/date "+%d%b %T")" - " >> $LOG
                /bin/echo "$1" >> $LOG
        fi
}

function email_error() {
        local MSG="$1"
        local ERROR_NO="${2:-"Unknown Error"}"
        /bin/echo $MSG | $MAILER -s "Error $ERROR_NO with rsync script on $HOSTNAME at $(/bin/date "+%d%b %T") hrs" $EMAIL
        write2log "emailed $MSG as error $ERROR_NO"
}

function email_progress() {
        local PROGRESS="$1"
        local MSG="$2"
        /bin/echo "$MSG" | $MAILER -s "Rsyncing on $HOSTNAME: progress = $PROGRESS%" $EMAIL
}

function set_lockfile() {
        write2log "setting lock file"
        /usr/bin/touch $LOCK
}

function remove_lockfile() {
        write2log "removing lock file"
        rm -f 2>/dev/null $LOCK
}

function debug() {
        echo "$1"
}

function preliminary_checks() {
        # root?
        check_root      # error 18

        # rsync still running, eg. from yesterday? - check for lock file - error 10
        if [ -f "$LOCK" ]; then
                email_error "Lock file exists at $LOCK, this normally means $0 is still running (check with ps aux). If the lock file was not correctly removed after the last exit remove it manually. Check log files at $LOG for more details." "10"
                write2log "lock file found at $LOCK, exiting ..."
                exit 1
        fi

        # do LOG, RSYNC_LOG exist?
        [[ ! -f "$LOG" ]] && (/usr/bin/touch "$LOG" && write2log "LOG did not exist - touched it")
        [[ ! -f "$RSYNC_LOG" ]] && (/usr/bin/touch "$RSYNC_LOG" && write2log "RSYNC_LOG did not exist - touched it")

        # are LOG, RSYNC_LOG writeable? - error 16
        if [[ ! -f "$LOG" || ! -f "$RSYNC_LOG" ]]; then
                email_error "Error rsyncing on $HOSTNAME: LOG and/or RSYNC_LOG not writeable" "16"
                write2log "LOG and/or RSYNC_LOG not writeable, exiting ..."
                exit 1
        fi

        # email working?
        if [ ! "$MAILER" ]; then
                write2log "mailer return non-zero exit status, exiting ..."
                exit 1
        fi

        # are SRCPATH, DSTPATH set? - error 14
        if [ "$SRCPATH" == "" -o "$DSTPATH" == "" ]; then
                email_error "Error rsyncing on $HOSTAME: SRCPATH and/or DSTPATH not set" "14"
                write2log "SRCPATH and/or DSTPATH not set, exiting ..."
                exit 1
        fi
}

function trap_received() {
        # email possible rsync errors - error no 30
        if [ $(grep 'rsync error' $RSYNC_LOG | wc -l) -gt "0" ]; then
                email_error "$(grep 'rsync error' $RSYNC_LOG)" "30"
        fi
        remove_lockfile
	mark_log_end
        exit 30
}

function mark_log_start() {
        # mark beginning of new log file entry
        /bin/echo "**************** begin *****************" >> $LOG
}

function mark_log_end() {
        # mark end of log file entry
        /bin/echo "***************** end ******************" >> $LOG
        /bin/echo "" >> $LOG
}

