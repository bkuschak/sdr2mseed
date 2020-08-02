#!/bin/sh
#
# Scan through a list of WinSDR files sorting them into unique groups with the 
# same parameters.
#
# To run this command with wildcards:
# (set -f && ./identify_sdr.sh /data/seismometer_data/psn/sys1.2019*.dat > out)
#

FILESET=$1
echo "Scanning $FILESET ..."
FILELIST=$(ls $FILESET |sort)
TEMPFILE=$(mktemp)

cat < /dev/null > $TEMPFILE
for i in $FILELIST; do
	# Example output from sdr2mseed -R -v:
	# Reading /data/seismometer_data/psn/sys1.20191216.dat
	#   fileVersionFlags: 0x02000002
	#   sampleRate:       200 (samples/second)
	#   numSamples:       1600
	#   numChannels:      8
	#   numBlocks:        1440
	#   lastBlockSize:    288024
	#   startTime:        1576454459 (2019-12-16 00:00:59)
	#   lastTime:         1576540799 (2019-12-16 23:59:59)
	#   lastBlockOffset:  414498572
	INFO=$(sdr2mseed -R -v $i 2>&1 |grep -E \
		'Reading|fileVersionFlags|sampleRate|numSamples|numChannels')

	# One line per file:
	echo $INFO >> $TEMPFILE
done

# Build an awk array to group files. Use these parameters as the unique keys:
# fileVersionFlags	$3, $4
# sampleRate		$5, $6
# numChannels		$10, $11
# numSamples		$8, $9
awk '{fname=$2; key=$3" "$4" "$5" "$6" "$10" "$11" "$8" "$9; 
     if (key in a) {a[key]=a[key]"\n"fname; count[key]++} 
     else {a[key]=fname; count[key]=1}} 
     END {for (i in a) {print "NumFiles: "count[i]" "i"\n"a[i]}}' \
	$TEMPFILE	

rm -f $TEMPFILE
