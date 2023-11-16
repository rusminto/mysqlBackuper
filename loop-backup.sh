#!/bin/bash

BACKUP_TIME="23:59:59"
LOCATION="/home/ypti/backup/mysqlBackuper"

while true
do
	currentTime="$(date "+%T")"
	echo $currentTime
	if [ $currentTime = $BACKUP_TIME ]; then
		echo "NOW, BACKUP TIME"
		/bin/bash $LOCATION/run
	fi
	sleep 1
done
