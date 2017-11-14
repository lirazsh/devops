#!/bin/bash - 
#===============================================================================
#          FILE: enable_l3.sh
#         USAGE: ./enable_l3.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 09/13/2017 09:18:50 AM EDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error
/home/liraz/devops/f5_ISP_manager.sh -i L3 -s NY -t 192.168.251.251 -o enable | mail -s "Critical: L3 Maintenance finished. Restored L3 traffic to NY. no need to call" ops_team@kaltura.opsgenie.net
