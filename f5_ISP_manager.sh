#!/bin/bash - 
#===============================================================================
#          FILE: f5_disable_ISP.sh
#         USAGE: ./f5_disable_ISP.sh 
#   DESCRIPTION: 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR:  (), @kaltura.com
#  ORGANIZATION: Kaltura, inc.
#       CREATED: 05/07/2017 07:29:55 AM EDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

_ISP="None"
_SITE="None"
_PA_IP=("192.168.101.3" "192.168.101.2")
_NY_IP=("192.168.251.251" "192.168.251.3")
_MASTER="None"
_VIP_LIST="None"

function exeCmd () {

	fetchVipList
	if [ "$1" == "modify" ]; then
		for i in $_VIP_LIST; do
			ssh $_MASTER "tmsh $1 ltm virtual $i $2"
		done
	fi
	if [ "$1" == "show" ]; then
		for i in $_VIP_LIST; do
			ssh $_MASTER "tmsh $1 ltm virtual $i"
		done
	fi
}

function fetchVipList () {

	_VIP_LIST="`ssh $_MASTER tmsh list ltm virtual | grep -i Monit | grep -i $_ISP | awk '{print $3}'`"
	
	echo "Selected VIPs are: "
	echo $_VIP_LIST
	userVer

}

function userVer () {

read -p "Are you sure you wish to continue([N]/y)? " user_sel
if [ "$user_sel" != "y" ]; then
	echo "Aborting..."
	main
fi 

}

function selectF5Master () {
	echo "Please choose a site:"
	echo "[1] PA"
	echo "[2] NY"
	echo "[8] Back"
	echo "[9] Exit"
	read -p "Your selection: " sel5

	echo "Site selected:"	

	case $sel5 in
		1) echo "PA"; _SITE="PA"
		;;
		2) echo "NY"; _SITE="NY"
		;;
		8) main
		;;
		9) echo "Goodbye..."; exit 0;
		;;
		*) selectF5Master
		;;
	esac


	echo "Please wait for a few seconds for the current config to be retrieved and choose the active F5 module:"
	if [ "$_SITE" == "PA" ]; then
		echo -e "[1] pa-lb3 (192.168.101.3) "; ssh 192.168.101.3 "tmsh show sys failover"
		echo -e "[2] pa-lb2 (192.168.101.2) "; ssh 192.168.101.2 "tmsh show sys failover"
		echo "[8] Back"
	fi
	if [ "$_SITE" == "NY" ]; then
		echo -e "[1] ny-lb4 (192.168.251.251) `ssh 192.168.251.251 "tmsh show sys failover"`"
		echo -e "[2] ny-lb3 (192.168.251.3) `ssh 192.168.251.3 "tmsh show sys failover"`"
		echo "[8] Back"
	fi

	read -p "User selection: " sel4
	if [ "$sel4" == "8" ]; then
		main
	fi
	if [ "$_SITE" == "PA" -a "$sel4" == "1" ]; then
		_MASTER="192.168.101.3"
		return 0
	fi
	if [ "$_SITE" == "PA" -a "$sel4" == "2" ]; then
		_MASTER="192.168.101.2"
		return 0
	fi
	if [ "$_SITE" == "NY" -a "$sel4" == "1" ]; then
		_MASTER="192.168.251.4"
		return 0
	fi
	if [ "$_SITE" == "NY" -a "$sel4" == "2" ]; then
		_MASTER="192.168.251.3"
		return 0
	fi
	כןש
	
echo "F5 master selection failed.. Aborting..."
exit 1

}

function querySite () {

	echo "Please select a site: "
	echo "[1] NY"
	echo "[2] PA"
	echo "[3] Back"
	echo "[9] Exit"
	read -p "Your selection: " usel2
	case $usel2 in
		1)  _SITE="NY"
			echo "NY selected..."
		;;
		2)  _SITE="PA"
			echo "PA selected..."
		;;
		3) main
		;;
		9) echo "Goodbye..."; exit 0;
		;;
		*) querySite
		;;
	esac
	
	return 0;

}

function main () {

echo "Welcome to the ISP-Manager. Please input your selection:"
echo "[1] Enable ISP"
echo "[2] Disable ISP"
echo "[3] Get ISP Status"
echo "[9] Exit"

read -p "Your selection: " sel

case $sel in
    1)
		queryISP
		if [ $? -ne 0 ]; then
		echo "ISP query returned an error when attempting to Enable ISP. Aborting..."; 
		main
		fi
		echo -e "Enabling ISP \"\e[96m$_ISP\e[39m\"..."
		if [ querySite -ne 0]; then
		echo "SITE query returned an error when attempting to select Site. Aborting...";
		main
		fi
		echo -e "Chose to enable \"\e[96m$_ISP\e[39m\" in site \"\e[96m$_SITE\e[39m\"."
		userVer
		selectF5Master
		enableISP
    ;;
	2) 
		queryISP
		if [ $? -ne 0 ]; then
        echo "ISP query returned an error when attempting to Disable ISP. Aborting...";
        fi
		echo -e "Disabling ISP \"\e[96m$_ISP\e[39m\"..."
		if [ querySite -ne 0]; then
        echo "SITE query returned an error when attempting to select Site. Aborting...";
        fi
        echo -e "Chose to disable \"\e[96m$_ISP\e[39m\" in site \"\e[96m$_SITE\e[39m\"."
		userVer
		selectF5Master
		disableISP
	;;
	3)
		queryISP
		if [ $? -ne 0 ]; then
        echo "ISP query returned an error when attempting to Query ISP. Aborting...";
        fi
		echo -e "Querying ISP \"\e[96m$_ISP\e[39m\"..."
		selectF5Master
		getISP
		main
	;;
    9) echo "Goodbye..." && exit 0;
    ;;
	*) echo "Invalid response" && main
	;;
esac

echo "Press any key to continue..."
read inp
main


}


function enableISP () {
	echo -e "Chose to \e[91menable \"\e[96m$_ISP\e[39m\" in site \"\e[96m$_SITE\e[39m\"."
    userVer
	exeCmd "modify" "enabled"
	echo "Done..."
	getISP
}

function disableISP () {
	echo -e "Chose to \e[91mdisable \"\e[96m$_ISP\e[39m\" in site \"\e[96m$_SITE\e[39m\"."
    userVer
	exeCmd "modify" "disabled"
	echo "Done..."
	getISP
}

function getISP () {
	echo -e "You have selected to \e[91mquery \e[39m \"\e[96m$_ISP\e[39m\" in site \"\e[96m$_SITE\e[39m\"."
	exeCmd "show"

}

function queryISP () {

echo "Please select the ISP:"
echo "[1] Zayo"
echo "[2] Cogent"
echo "[3] L3"
echo "[8] Back"
echo "[9] Exit"

read -p "Your selection: " usel

case $usel in
	1) _ISP="Zayo" && echo -e "Selected \"\e[96mZayo\e[39m\" as the ISP";
	;;
	2) _ISP="Cogent" && echo -e "Selected \"\e[96mCogent\e[39m\" as the ISP";
	;;
	3) _ISP="L3" && echo -e "Selected \"\e[96mL3\e[39m\" as the ISP"; 
	;; 
	8) echo "Going back per user\'s request..."; return 1;
	;;
	9) echo "Goodbye..."; exit 0;
	;;
	*) echo "Invalid selection, please try again"; queryISP;
	;;
esac

#read -p "Selected \"\e[96m$_ISP\e[49m\" as the ISP. Are you sure ([N]/y)? " res
#if [ "$res" != "y" ]; then
#	_ISP="None"
#	echo "Aborting per user\'s response..."
#	sleep 2
#	return 1
#fi

return 0

}

main
