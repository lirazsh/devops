#!/bin/bash - 
#===============================================================================
#          FILE: checkConnectionDist.sh
#         USAGE: ./checkConnectionDist.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 11/14/2017 08:25:37 AM EST
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

MAX_VOD_NUMBER_PA=12
MAX_VOD_NUMBER_NY=12
RECORDS_TO_DISPLAY=10

for arg in $@; do
	case "$arg" in
		"-pa") 
			for i in $(seq 1 $MAX_VOD_NUMBER_PA); do 
				echo "------------"
				echo -e "host: pa-front-vod$i"
				ssh pa-front-vod$i	netstat -nap | awk '{print $5}' | sed 's/\:.*$//g' | egrep '^[1-9]' | sort | uniq -c  | sort -n | tail -"$RECORDS_TO_DISPLAY"
			done
		;;

		"-ny")
			for i in  $(seq 1 $MAX_VOD_NUMBER_NY); do
				 echo "------------"
                 echo -e "host: ny-front-vod$i"
				 ssh ny-front-vod$i  netstat -nap | awk '{print $5}' | sed 's/\:.*$//g' | egrep '^[1-9]' | sort | uniq -c  | sort -n | tail -"$RECORDS_TO_DISPLAY"
			done
		;;
		*)
			echo -e "Usage: $0 [-pa][-ny]"
			echo ""
			echo "-pa     display VOD client connections for site PA"
			echo "-ny     display VOD client connections for site NY"
	esac
done
