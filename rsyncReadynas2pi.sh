#!/bin/bash

# rsyncReadynas2pi.sh
# script rsyncs files from readynas to either cinnamon or caraway (RPi's)
# usage: rsyncReadynas2pi.sh <src_path> <dst_path> <|dry>
# sgr 11jan16
# version 1.0

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


### main ###

# correct arguments supplied?
if [ "$#" == "2" -o "$#" == "3" ]; then
	SRCPATH="$1"; DSTPATH="$2"; DRY="$3"
     	echo; echo "will rsync files from $SRCPATH to $DSTPATH"
		[[ "$DRY" ]] && echo " doing a test run only (dry)"
else
	echo; echo "Incorrect number of arguments!"
	display_usage
fi

# rsync still running, eg. from yesterday?
