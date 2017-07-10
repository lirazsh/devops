#!/bin/bash
#For more details use the following document https://portal.kaltura.com/ProdIT/_layouts/WordViewer.aspx?id=/ProdIT/Install%20Procedures/Kaltura_Server_Installation_Process.docx&Source=https%3A%2F%2Fportal%2Ekaltura%2Ecom%2FProdIT%2FInstall%2520Procedures%2FForms%2FAllItems%2Easpx&DefaultItemOpen=1


function create_mounts () 
{
    mkdir /webtmp
    chmod 777 /webtmp
    mkdir /web2

    cp /etc/fstab /etc/fstab.`date +%d_%m_%y`
    INTERFACE=`ip addr sh | grep "state UP" | awk -F : '{print $2 }'`
    if [ -z $INTERFACE ] ; then
       echo "Cant find active interface, Exiting"
       exit 1 
    fi
    echo "$INTERFACE is up, press any key" ; read userInput
    designatedVlan=`ifconfig $INTERFACE| grep addr:192 | awk '{print $2}' | cut -d":" -f2 | cut -d"." -f3`
    if [ -z "$designatedVlan" ]; then
       echo "cant find designated IP addr exiting..."
       exit 1
    fi

        case $designatedVlan in
                11)
                        isilonMount="pa-isilon-front"
                        ;;
                21)
                        isilonMount="pa-isilon-db"
                        ;;
                31)
                        isilonMount="pa-isilon-backend"
                        ;;
                131)
                        isilonMount="pa-isilon-apps"
                        ;;
                61)
                        isilonMount="pa-isilon-batchapi"
                        ;;
                252)
                        isilonMount="pa-isilon"
                        ;;
		10)
                        isilonMount="ny-isilon-front"
                        ;;
                20)
                        isilonMount="ny-isilon-db"
                        ;;
                30)
                        isilonMount="ny-isilon-backend"
                        ;;
                130)
                        isilonMount="ny-isilon-apps"
                        ;;
                60)
                        isilonMount="ny-isilon-batchapi"
                        ;;
                251)
                        isilonMount="ny-isilon"
                        ;;
		*)     	echo "cant file vlan $designatedVlan... exiting.."
			exit 3
			;; 
        esac
    if grep isilon /etc/fstab -q ; then
       echo "isilon alreay mounted..."
     else 
       echo "adding $isilonMount to fstab"
       echo "${isilonMount}:/ifs/web2 /web2 nfs" >> /etc/fstab
    fi

    mount -a

    ln -sf /web2 /web
    if [[ "$HOSTNAME" =~ ^pa-.* ]] ; then
       echo "script is running on pa - setting pa mounts on fstab, press any key to continue" ; read userInput
       #echo Creating legacy /web3 for old links like /web//content/r71v1/
       ln -fs /web2 /web3
    fi

    touch /web/.zhealthcheck
    if [ $? -ne 0 ] ; then
       echo "something went wrong, unable to write to /web"
       exit 10  
    fi
    #echo ">>> Mount leagcy Mounts?(y/N)[y]" ; read userInput
    #if  [ "$userInput" == "y" ] || [ -z "$userInput" ] ; then
    #   if grep head /etc/fstab -q ; then
    #      echo "leagcy mounts exsists on fstab, mounts will NOT added to fstab "
    #   else 
    #      ssh $SOURCEHOST 'grep head /etc/fstab' >> /etc/fstab
    #      mount -a
    #   fi
    #fi
}



function install_basic 
{ 
	MOTD="/etc/update-motd.d/97-kaltura"
	if [ ! -r "$MOTD" ];then
	    echo '#!/bin/sh' >> $MOTD
	    echo 'echo "#########################################################################################################"' >> $MOTD
	    echo 'echo "This machine is in maint. mode"'>> $MOTD
	    echo 'echo "Do not do anything without first checking with it.prod."' >> $MOTD
	    echo 'echo "#########################################################################################################"' >> $MOTD
	    chmod +x $MOTD
	fi
	#KALTURA_PROFILE=/etc/profile.d/kaltura.sh
	IT_MAIL_ADDR=production-it@kaltura.com

	#Set Local kaltura repo
	case "$(lsb_release -rs)" in
	16.04)
		#adding specific requirements for Ubuntu 16.04 - lirazs 9/1/17
		apt-get install aptitude binutils -y
		echo "No repo for $(lsb_release -rs) leaving system default"
        ;;

        14.04) 
		echo "No repo yet for $(lsb_release -rs) leaving system default"
        ;;

        12.04)
		echo "Setting Local kaltura repo sources from $SOURCEHOST"	
		cp /etc/apt/sources.list /etc/apt/sources.list.orig
		scp -oStrictHostKeyChecking=no $SOURCEHOST:/etc/apt/sources.list /etc/apt/sources.list

        ;;

        *)
		echo "Could not fins repo for $(lsb_release -rs) leaving system default"
        ;;
	esac

	echo "Installing Packages anf upgrading system to latest state"
	export DEBIAN_FRONTEND=noninteractive
	aptitude update && aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y dist-upgrade && aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y install  ipmitool vim-nox nscd snmpd ethtool rpcbind htop mcrypt iotop sysstat ntp dstat apt-file mailutils htop gt5 nfs-common php5-cli php5-mysql vim-nox git perl ccze strace bmon sysstat mtr sshpass postfix unzip nmap links2 iptraf zip sysv-rc-conf mutt most iftop smem -y
	# For colorfull man pages
#	aptitude --allow-unauthenticated install most  
#Install a newer HWE version        
aptitude -o Aptitude::Cmdline::ignore-trust-violations=true -y  install linux-generic-lts-trusty linux-image-generic-lts-trusty

	apt-file update

	service ntp start
	service postfix start

	#Set default startup
	update-rc.d postfix defaults
	update-rc.d ntp defaults

	echo ">>> checking mail..."
	#Check email
	echo "Ubuntu config script was executed on" $(hostname -s) " this mean that email is configured properly."  | mail -s "`dirname $0`: Ubuntu configuration script" $IT_MAIL_ADDR

	#Copy ztail - added By GE 20150215
	scp $SOURCEHOST:/usr/bin/ztail /usr/bin/ztail
} 

if echo "$HOSTNAME" | grep -q "pa-" ; then
        echo "script is running on pa - setting SOURCEHOST to pa-front-api21"
        SOURCEHOST=pa-front-api21
else
        echo "script is running on ny - setting SOURCEHOST to ny-front-api21"
        SOURCEHOST=ny-front-api21
fi

if ! ping -c 1  $SOURCEHOST ; then
   echo "$SOURCEHOST is unresponsive!!!, pls update script with operational server"
   exit 1
fi

echo "This script is going to configure basic production server installation, press any key..." ; read userInput
echo "This script is going to restart network services..."
/etc/init.d/networking restart

echo ">>> Creating Server keys"
ssh-keygen -q -N "" -f /root/.ssh/id_rsa
#ssh-keygen

echo ">>> Copy keys to $SOURCEHOST..."
ssh -q -o "StrictHostKeyChecking no" -o PasswordAuthentication=no $SOURCEHOST false
ssh-copy-id $SOURCEHOST

echo ">>> Setting up www-data as UID 48..." 
sedCommand="s/www-data:x:33:33/www-data:x:48:48/"
cp /etc/passwd /etc/passwd.`date +%d_%m_%y`
sed -i $sedCommand /etc/passwd

sedCommand="s/www-data:x:33:/www-data:x:48:/"
cp /etc/group /etc/group.`date +%d_%m_%y`
sed -i $sedCommand /etc/group


echo ">>> Installing basic pkgs, press any key to proceed" 
install_basic


echo ">>> Mount /web?(y/N)[y]" ; read userInput
if  [ "$userInput" == "y" ] || [ -z "$userInput" ] ; then
   create_mounts
else
   echo "skipping..."
fi


echo ">>> add pa-admin key to authorized_keys?(y/N)[y]" ; read userInput
if  [ "$userInput" == "y" ] || [ -z "$userInput" ] ; then
   echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvxaIu1iczT9RH5Xc0LwNNrlNmatpUfsS+Bne3Z+18hHk1GjtBPlkYLgM5xjP0/F5HNZ0DyyhYr/nJbD5JWbBIVi/CgwI44ZB/xAhpYNZVm/uRgo99317KeQXrZZvPwBi6PNNGSVYClaPg39gPIH5Go8srI4tSFg9pfASaOi9DPULbCKTDo+JmUBljC4xUbcoI6OBZUrBKHUx80bjjDz0nPZDpaqiIwUvpECy/tK7umxl4NkbeaWPe2HiPSADAIlzPhLxJsqXnsbw7ic0KiCjo5rM35j8WYCyatr3b/WdGbDixyuIpX6wYnqPvoJUi2ro4iWzuY0U018VGaPmeOvTRw== root@pa-admin" >> ~/.ssh/authorized_keys
else
   echo "keys are not generated."
fi

rsync -a $SOURCEHOST:/root/.vim /root --exclude=tmp --exclude=back
mkdir -p /root/.vim/tmp /root/.vim/back

echo ">>> SNMP service Configuration" 
cp -f /web/kaltura/install/snmp/snmp.conf /web/kaltura/install/snmp/snmpd.conf /etc/snmp/ 
cp -f /web/kaltura/install/snmp/snmpd /etc/default/snmpd 
service snmpd restart
update-rc.d snmpd defaults


# for color PS1:
scp $SOURCEHOST:/etc/profile.d/color.sh /etc/profile.d/
scp $SOURCEHOST:/root/.bash_login ~/
scp $SOURCEHOST:/etc/profile.d/kaltura.sh /etc/profile.d/kaltura.sh


scp $SOURCEHOST:/etc/ssh/sshd_config /etc/ssh/sshd_config
scp $SOURCEHOST:/etc/ssh/ssh_config /etc/ssh/ssh_config

#Create additional users
USERS_TO_CREATE='dev:::fanta.Zero!3 zenoss'
for USER1 in $USERS_TO_CREATE ;do
        DA_USER=`echo $USER1|awk -F ":::" '{print $1}'`
        DA_PASSWD=`echo $USER1|awk -F ":::" '{print $2}'`

        /web/iTscripts/create_user.sh $DA_USER $DA_USER $DA_PASSWD
done
rm -rf /home/zenoss
rsync -av $SOURCEHOST:/home/zenoss/ /home/zenoss/
# just in case the permissions from source are wrong..
chown -R zenoss.zenoss /home/zenoss
#set /bin/bash as shell for zenoss
chsh -s /bin/bash zenoss

