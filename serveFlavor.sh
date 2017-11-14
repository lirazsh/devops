#!/bin/sh
 
DIR_PATH=/etc/node_exporter/data
METRIC=front_vod_serveFlavor
 
LOCKFILE="/var/run/node_exporter_SF.pid"
 
 
#Check if there is a lock file from previous run and the process is still running
if [ -f $LOCKFILE ] && ( ps -p `cat $LOCKFILE` 1>/dev/null 2>/dev/null ); then
                             
                             #report -1 back to Prometheus to indicate an issue and kill the process
                             RES="-1"
                             kill -9 `cat $LOCKFILE`
                                                                                                                
else
#There is no locking process 
 
                             echo $$ > $LOCKFILE
                             RES=`ztail -n 10000 /var/log/nginx/access_log.gz | python /web/iTscripts/crons/filterTime.py 3 '[%d/%b/%Y:%H:%M:%S' 120 |zgrep serveFlavor|awk '$10*1>=100000 {print int($11*2097152/$10)}'|awk '{s++; d=int($1); if (d==0) t+=100} END {print t/s}'`                             
fi
 
 
 
 
#report results to Prometheus
echo "$METRIC $RES" > $DIR_PATH/$METRIC.prom.$$
mv $DIR_PATH/$METRIC.prom.$$ $DIR_PATH/$METRIC.prom
 
#clear lock file before exiting the shell
rm $LOCKFILE
