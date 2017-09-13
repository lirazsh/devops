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

_PA_HA_GROUP="PA-HA-Group"
_NY_HA_GROUP="HA-Group"
_ISP="None"
_SITE="None"
_PA_IP=("192.168.101.3" "192.168.252.4")
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
	if [ "$_ISP" != "ALL" ]; then
		_VIP_LIST="`ssh $_MASTER tmsh list ltm virtual | grep -i Monit | grep -i $_ISP | awk '{print $3}'`"
	else
		_VIP_LIST="`ssh $_MASTER tmsh list ltm virtual | grep -i Monit | grep ltm | awk '{print $3}'`"
	fi
	
	if ! [ $SILENT ]; then
		 echo "Selected VIPs are: "
		 echo $_VIP_LIST
		 userVer
	fi

}

function userVer () {

read -p "Are you sure you wish to continue([N]/y)? " user_sel
if [ "$user_sel" != "y" ]; then
	echo "Aborting..."
	main
fi 

}

function selectF5Master () {
	echo -e "\e[92mPlease choose a site:\e[39m"
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


	echo "Please wait for a few seconds for the current config to be retrieved and choose the relevant F5 module:"
	if [ "$_SITE" == "PA" ]; then
		echo -e "[1] pa-lb3 (192.168.101.3) "; ssh 192.168.101.3 "tmsh show sys failover"
		echo -e "[2] pa-lb4 (192.168.252.4) "; ssh 192.168.252.4 "tmsh show sys failover"
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
		_MASTER="192.168.252.4"
		return 0
	fi
	if [ "$_SITE" == "NY" -a "$sel4" == "1" ]; then
		_MASTER="192.168.251.251"
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

	echo -e "\e[92mPlease select a site: \e[39m"
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

echo -e "\e[92mWelcome to the ISP-Manager" 
echo -e "Please type your selection:\e[39m"
echo "[1] Enable ISP"
echo "[2] Disable ISP"
echo "[3] Get ISP Status"
echo "[7] Sync changes"
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
		if [ querySite == "0" ]; then
		echo "SITE query returned an error when attempting to select Site. Aborting...";
		main
		fi
		#echo -e "Chose to enable \e[96m\"$_ISP\"\e[39m in site \e[96m\"$_SITE\"\e[39m."
		selectF5Master
		#userVer
		enableISP
    ;;
	2) 
		queryISP
		if [ $? -ne 0 ]; then
        echo "ISP query returned an error when attempting to Disable ISP. Aborting...";
        fi
		echo -e "Disabling ISP \"\e[96m$_ISP\e[39m\"..."
		if [ querySite == "0" ]; then
        echo "SITE query returned an error when attempting to select Site. Aborting...";
        fi
        #echo -e "Chose to disable \e[96m\"$_ISP\"\e[39m in site \e[96m\"$_SITE\"\e[39m."
		selectF5Master
		#userVer
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
	7)
		syncF5
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
	echo -e "Chose to \e[91menable \e[96m\"$_ISP\"\e[39m in site \e[96m\"$_SITE\"\e[39m."
    #userVer
	exeCmd "modify" "enabled"
	echo "Done..."
}

function disableISP () {
	echo -e "Chose to \e[91mdisable \e[96m\"$_ISP\"\e[39m in site \e[96m\"$_SITE\"\e[39m."
    #userVer
	exeCmd "modify" "disabled"
	echo "Done..."
}

function getISP () {
	echo -e "You have selected to \e[91mquery \e[39m \e[96m\"$_ISP\"\e[39m in site \e[96m\"$_SITE\"\e[39m."
	exeCmd "show"

}

function queryISP () {

echo -e "\e[92mPlease select the ISP:\e[39m"
echo "[1] Zayo"
echo "[2] Cogent"
echo "[3] L3"
echo "[7] ALL"
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
	7) _ISP="ALL" && echo -e "Selected \"\e[96mALL\e[39m\" ISPs";
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

function sync_to_group () {
	echo -e "You are about to sync \e[5m\e[91m$_MASTER\e[39m\e[0m to \e[5m\e[93mgroup\e[0m\e[39m."
	read -p "Are you sure to wish to continue ([N]/y)? " res
	if [ "$res" != "y" ]; then
		echo "Aborted..."
		main
	fi

	if [ "$_SITE" == "PA" ]; then
		ssh $_MASTER "tmsh run cm config-sync to-group $_PA_HA_GROUP"
	fi
    if [ "$_SITE" == "NY" ]; then
		ssh $_MASTER "tmsh run cm config-sync to-group $_NY_HA_GROUP"
	fi
	echo "Done..."
    read -p "Press Enter to continue..."

}
function sync_from_group () {
	echo -e "You are about to sync \e[5m\e[93mgroup\e[39m\e[0m to \e[5m\e[91m$_MASTER.\e[39m\e[0m"
	read -p "Are you sure to wish to continue ([N]/y)? " res
	if [ "$res" != "y"]; then
		echo "Aborted..."
	    main
	fi

	if [ "$_SITE" == "PA" ]; then
		ssh $_MASTER "tmsh run cm config-sync from-group $_PA_HA_GROUP"
    fi
    if [ "$_SITE" == "NY" ]; then
		ssh $_MASTER "tmsh run cm config-sync from-group $_NY_HA_GROUP"
    fi
	echo "Done..."
	read -p "Press Enter to continue..."

}

function syncF5 () {
	echo -e "\e[92mPlease select the F5 module to sync from/to:\e[39m"
	selectF5Master
	echo "Please select the desired operation:"
	echo "[1] Sync device to group"
	echo "[2] Sync group to device"
	echo "[8] Back"
	echo "[9] Exit"
	read -p "Your selection: " user_sel
	
	case $user_sel in
		1) sync_to_group
		;;
		2) sync_from_group
		;;
		8) main
		;;
		9) echo "Goodbye..."; exit 0
		;;
		*) echo "Invalid choice, aborting..."; main;
		;;
	esac
	main

}

if [ $# -eq 0 ]; then
	main
	exit 0;
elif [ $# -ne 8 ]; then
	echo "Incorrect number of args given..."
	exit 1;
fi

echo "auto run"
SILENT="true"
while getopts "i:s:t:o:" opt; do
	case $opt in
		i)
			case $OPTARG in
				L3)
					echo "ISP:L3"
					_ISP="L3"
				;;
				ZA)
					echo "ISP:Zayo"
					_ISP="Zayo"
				;;
				CO)
					echo "ISP:Cogent"
					_ISP="Cogent"
				;;
				ALL)
					echo "ISP:ALL"
					_ISP="ALL"
				;;
				*)
					echo -e "Invalid ISP $OPTARG.\nAvailable ISPs:\n\"L3\" - Level3\n\"ZA\" - Zayo\n\"CO\" - Cogent\n\"ALL\" - All ISPs"
					exit 1;
				;;
			esac
			
		;; 
		s)
			echo "Site:$OPTARG"
			_SITE="$OPTARG"
			if [ "$OPTARG" != "NY" ] && [ "$OPTARG" != "PA" ]; then
				echo -e "Invalid site: $_SITE";
				exit 1;
			fi
		;;
		t)
			echo "Target:$OPTARG"
			_MASTER="$OPTARG"
		;;
		o)
			echo "OP:$OPTARG"
			if [ "$OPTARG" == "enable" ]; then
				_OP="Enable"
			elif [ "$OPTARG" == "disable" ]; then
				_OP="Disable"
			else
				echo -e "Invalid operation: $OPTARG"
				exit 1;
			fi
		;;
		*)
			echo -e "invalid flag -$OPTARG"
		;;
	esac
done;

echo -e "Date:$(date)"

if [ "$_OP" == "Enable" ]; then
	exeCmd "modify" "enabled"
elif [ "$_OP" == "Disable" ]; then
	exeCmd "modify" "disabled"
fi

exeCmd "show" | grep -e "Ltm::Virtual" -e "State"

#_NY_HA_GROUP="HA-Group"
#_ISP="None"
#_SITE="None"
#_PA_IP=("192.168.101.3" "192.168.252.4")
#_NY_IP=("192.168.251.251" "192.168.251.3")
#_MASTER="None"
#_VIP_LIST="None"


