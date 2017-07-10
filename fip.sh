#!/bin/bash - 
#===============================================================================
#          FILE: fip.sh
#         USAGE: ./fip.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 07/10/2017 09:30:13 AM EDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error
echo ""
echo ""
echo "Welcome to IP-Finder"
echo "I will easily find matching free ip addresses for you!"
read -p "First vlan (i.e.\"10\" for 192.168.10.X): " vlan1
read -p "Second vlan: " vlan2

for i in {2..254}; do 
	if ! ping -W 2 -c 1 -q 192.168.$vlan1.$i > /dev/null ; then 
		if ! ping -W 2 -c 1 -q 192.168.$vlan2.$i > /dev/null; 
			then echo -e "free address: 192.168.$vlan1.$i, 192.168.$vlan2.$i" ; 
		fi; 
	fi; 
done;


