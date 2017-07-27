#!/bin/bash - 
#===============================================================================
#          FILE: VOD-ServeFlavor.sh
#         USAGE: ./VOD-ServeFlavor.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 07/27/2017 09:26:27 AM EDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error
#!/bin/sh

source /tmp/sf_ts 2>/dev/null # file keeps tracks of resets
_firstReset=${firstReset:-0}
_secondReset=${secondReset:-0}
_lastReset=${lastReset:-0}

currentTime=$(date +%s)
elapsed=$(( $currentTime - $_firstReset ))

DIR_PATH=/etc/node_exporter/data
METRIC=front_vod_serveFlavor

LOCKFILE="/var/run/node_exporter_SF.pid"


#Check if there is a lock file from previous run and the process is still running
if [ -f $LOCKFILE ] && ( ps -p `cat $LOCKFILE` 1>/dev/null 2>/dev/null ); then
                             
                             #report -1 back to Prometheus to indicate an issue
                             RES="-1"
                             
                             #Check if time from oldest reset is less than 1 hour
                             if [ $elapsed -lt 3600 ] ; then
                                           
                                           #Check if an email was sent already regarding this issue; if so, do nothing
                                           if [ ! -f /tmp/sf_email_sent ]; then
                                                          text_message="The script /etc/node_exporter/scripts/serveFlavor.sh hung more than 3 times in the past 60 minutes.\n Script cannot reset more than 3 times every 60 minutes. Please investigate! \n\n To resume script auto-recovery, delete /tmp/sf_ts.\n Script will recover termination functionality automatically in up to 60 minutes."
                                                          echo -e "$text_message" | mail -s "VOD ServeFlavor monitoring issue" vod.serve.flavor@kaltura.opsgenie.net
                                                          touch /tmp/sf_email_sent
                                           fi
                             
                             else #if oldest reset is more than 1 hour old, reset and update state vars
                             
                                           kill -9 `cat $LOCKFILE`
                                           
                                           _firstReset=$_secondReset
                                           _secondReset=$_lastReset
                                           _lastReset=$currentTime
                                           
                                           #update state vars in file
                                           echo "#state file for ServeFlavor.sh used for VOD ServeFlavor reporting" > /tmp/sf_ts
                                           echo "#Path: /etc/node_exporter/scripts/serveFlavor.sh" >> /tmp/sf_ts
                                           echo -e "createTime=$currentTime" >> /tmp/sf_ts
                                           echo -e "firstReset=$_firstReset" >> /tmp/sf_ts
                                           echo -e "secondReset=$_secondReset" >> /tmp/sf_ts
                                           echo -e "lastReset=$_lastReset" >> /tmp/sf_ts
                             fi
                             
                             

else #There is no locking process
                             echo $$ > $LOCKFILE
                             RES=`ztail -n 10000 /var/log/nginx/access_log.gz|zgrep serveFlavor|awk '$10*1>=100000 {print int($11*2097152/$10)}'|awk '{s++; d=int($1); if (d==0) t+=100} END {print t/s}'`
                             if [ $? -ne "0" ]; then RES="-1"; fi
                             
                             #If time since last reset is more than 1 hour, update the counter accordingly
                             
                             if [ -f /tmp/sf_email_sent ]; then rm /tmp/sf_email_sent; fi;
fi




#report results to Prometheus
echo "$METRIC $RES" > $DIR_PATH/$METRIC.prom.$$
mv $DIR_PATH/$METRIC.prom.$$ $DIR_PATH/$METRIC.prom

#clear lock file before exiting the shell
rm $LOCKFILE


