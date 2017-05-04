#!/bin/bash - 
#===============================================================================
#          FILE: isi_create_snapshot.sh
#         USAGE: ./isi_create_snapshot.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 05/04/2017 08:48:28 AM EDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

_USER="mysql"
_PASS="mysql"
_IP=192.168.101.221
_PORT=8080
_COOKIE="null"
_PATH="/ifs/data/mysql/pa-db10"
_SNAP_PREFIX="mysql"
_EXP="1209600" # expiration of the snapshot: epoch 14 days




#Get authorization cookie
_COOKIE=$(curl -i -k -H 'Content-type: application/json' -X POST -d "{ \"username\":\"$_USER\",\"password\":\"$_PASS\",\"services\":[\"platform\",\"namespace\"] }" https://$_IP:$_PORT/session/1/session 2>/dev/null | grep Set-Cookie | awk '{print $2}' | tr -d ';' )

#echo $_COOKIE
#curl -k -i -XGET https://$_IP:$_PORT/platform/1/snapshot/license -b "$_COOKIE"

#Create the snapshot
result=$(curl -k -i -XPOST https://$_IP:$_PORT/platform/1/snapshot/snapshots -d "{ \"name\":\"$_SNAP_PREFIX-$(date +%Y-%b-%d_%H:%M:%S_%Z)\",\"path\":\"$_PATH\",\"expires\":$((`date +%s`+$_EXP)) }" -b "$_COOKIE" 2>/dev/null | grep -i http )


if [ "`echo $result  | awk '{print $2}'`" == "201" ]; then
	exit 0 #success
else
	exit 1 #failure
fi
