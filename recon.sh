#!/bin/bash

#This script will perform full enumeration scanning of the host
#including:
# *nmap full scan
# *nmap detailed scans
# *web scanning with nikto, dirb, GoBuster
# *web page brute force of nonstd http ports
# *nmap NSE scripts against: SMB, FTP,

#############
# Functions`#
#############
#####################################################################################

############
#help menu #
############

usage() {
	echo
	echo "Usage: $(basename ${0}) -i <IP Address> <options>" >&2
	echo
	echo "This program runs full enumeration on a specified host"
	echo
	echo 'OPTIONS:'
	echo
	echo '-h Display this help menu'
	echo '-i <IP>	Specify IP address to scan'
	echo '-n Skip non-std web scans'
	echo '-s Skip nmap scripts'
	echo '-q Specify quiet mode. (Runs without Banner).'
	echo '-w Skip web scans'
	echo
	echo
	exit 1
}
########################
# Check if IP is Valid #
########################

function valid_ip()
{
    local  ip=$IP
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
		if [[ $stat -ne 0 ]]
		then
			echo
		 	echo 'Please enter a valid IP.'
			echo
			exit 1
		fi

}


#############
# nmap full #
#############

# Check if scan wanted
check_scan_wanted() {
	if [[ $scan_wanted == y ]]
	then
		nmap_full
		scan_wanted='n'
	fi
}

check_dscan_wanted() {
	if [[ $dscan_wanted == y ]]
	then
		nmap_detailed
		dscan_wanted='n'
	fi
}

check_uscan_wanted() {
	if [[ $uscan_wanted == y ]]
	then
		nmap_udp
		uscan_wanted='n'
	fi
}

check_udscan_wanted() {
	if [[ $udscan_wanted == y ]]
	then
		nmap_udp_detailed
		udscan_wanted='n'
	fi
}

# Full Scan
nmap_full() {
echo
echo "********** Running full scan on $IP **********"
echo "Saving to ${filepath}/full_scan ......"
nmap $IP -p- -sS -Pn -T4 > "$filepath/full_scan"
wait
if [[ "${?}" -ne 0 ]]
then
	echo 'nmap full scan failed.'
	exit 1
else
	echo 'Full scan finished.'
	echo
fi
chown $user: $filepath/full_scan
}

#################
# nmap detailed #
#################
# Run Detailed Scan
nmap_detailed() {
echo
echo "********* Starting detailed nmap scan of $IP **********"
echo "Scanning port #s $ports."
nmap $IP -p $ports -sV -sC -A --reason -Pn --version-intensity 9 > $filepath/detailed_scan
if [[ "${?}" -ne 0 ]]
then
	echo 'nmap detailed scan failed.'
	exit 1
else
	echo 'Detailed scan finished.'
	echo
fi
chown $user: $filepath/detailed_scan
}

# UDP Scan
nmap_udp() {
echo
echo "********** Running udp scan on $IP **********"
echo "Saving to ${filepath}/udp_scan ......"
nmap $IP  -sU -Pn -T3 --top-ports=100 > "$filepath/udp_scan"
wait
if [[ "${?}" -ne 0 ]]
then
	echo 'nmap udp scan failed.'
	exit 1
else
	echo 'UDP scan finished.'
	echo
fi
chown $user: $filepath/udp_scan
}

#UDP detailed
nmap_udp_detailed() {
echo
echo "********* Starting UDP detailed nmap scan of $IP **********"
echo "Scanning port #s $uports."
nmap $IP -p $uports -sU -sV -A --reason -Pn -O > $filepath/udp_detailed_scan
if [[ "${?}" -ne 0 ]]
then
	echo 'nmap UDP detailed scan failed.'
	exit 1
else
	echo 'UDP Detailed scan finished.'
	echo
fi
chown $user: $filepath/udp_detailed_scan
}

#########
# links #
#########
download_links_http() {
echo
echo "********** Downloading Links HTTP *************"
echo "Links for HTTP webpage: " > $filepath/web_links
curl $IP -s -L | grep "title\|href" | sed -e 's/^:space:*//' >> $filepath/web_links
echo >> $filepath/web_links
chown $user: $filepath/web_links
echo "Download Complete."
}

download_links_https() {
echo
echo "********** Downloading Links HTTPS *************"
echo "Links for HTTPS webpage: " > $filepath/web_links
curl $IP -s -L | grep "title\|href" | sed -e 's/^:space:*//' >> $filepath/web_links
echo >> $filepath/web_links
chown $user: $filepath/web_links
echo "Download Complete."
}

##############
# Robots.txt #
##############
download_robots(){
echo
if [[ $http == true ]]
then
	echo '********** Downloading HTTP Robots.txt **************'
	echo >> $filepath/robots.txt
	echo 'HTTP Robots.txt: ' >> $filepath/robots.txt
else
	echo '********** Downloading HTTPS Robots.txt **************'
	echo 'HTTP Robots.txt: ' >> $filepath/robots.txt
	echo >> $filepath/robots.txt
fi
curl robots_url -s | html2text >> $filepath/robots.txt
echo >> $filepath/robots.txt
chown $user: $filepath/robots.txt
echo 'Download Complete.'
echo
}

#############
# Web Scans #
#############
web_scans() {
if [[ $http == true ]]
then
	echo '********** Starting GoBuster Scan on HTTP **************'
	gobuster dir -k -u http://$IP -w /usr/share/seclists/Discovery/Web-Content/big.txt > $filepath/gobuster_80
	chown $user: $filepath/gobuster_80
	echo 'GoBuster scan completed.'
	echo
	echo '********** Starting Dirb Scan on HTTP **************'
	dirb http://$IP/ -r > $filepath/dirb_80
	chown $user: $filepath/dirb_80
	echo 'Dirb scan completed.'
	echo
	echo '********** Starting Nikto Scan on HTTP **************'
	nikto -host http://$IP > $filepath/nikto_80
	chown $user: $filepath/nikto_80
	echo 'Nikto scan completed.'

else
	echo '********** Starting GoBuster Scan on HTTPS **************'
	gobuster dir -k -w /usr/share/seclists/Discovery/Web-Content/big.txt -u https://$IP/ > $filepath/gobuster_443
	chown $user: $filepath/gobuster_443
	echo 'GoBuster scan completed.'
	echo
	echo '********** Starting Dirb Scan on HTTPS **************'
	dirb https://$IP/ -r > $filepath/dirb_443
	chown $user: $filepath/dirb_443
	echo 'Dirb scan completed.'
	echo
	echo '********** Starting Nikto Scan on HTTPS **************'
	nikto -host https://$IP > $filepath/nikto_80
	chown $user: $filepath/nikto_80
	echo 'Nikto scan completed.'
fi
}

check_skip_web() {
if [[ $web_scanning == true ]]
then
	download_links_http
	download_robots
	web_scans
fi
}

# Non Standard HTTP Dirb scans
nonstand_http_scan() {
if [[ $nonstd_scanning == true ]]
then
	echo
	echo "********** Performing Dirb on http://$IP:$1 **********"
	dirb http://$IP:$1 -S -r >> $filepath/dirb_nonstd
	echo >> $filepath/dirb_nonstd
	echo "finished."
	echo
fi
}


################
# Nmap Scripts #
################

smb_enum() {
if [[ $nmap_scripts == true ]]
then
	echo
	echo '********** Starting nmap SMB enumeration script **************'
	sudo nmap --script=smb-enum-shares $IP > $filepath/smb
	chown $user: $filepath/smb
	echo 'script completed.'
fi
}

ftp_enum() {
if [[ $nmap_scripts == true ]]
then
	echo
	echo '********** Starting nmap FTP enumeration script **************'
	echo 'FTP Anon: ' > $filepath/ftp_enum
	echo >> $filepath/ftp_enum
	sudo nmap --script=ftp-anon $IP >> $filepath/ftp_enum
	echo >> $filepath/ftp_enum
	echo 'FTP Brute: ' >> $filepath/ftp_enum
	echo >> $filepath/ftp_enum
	sudo nmap --script=ftp-brute $IP -p 21 >> $filepath/ftp_enum
	chown $user: $filepath/ftp_enum
	echo 'FTP scripts completed.'
	echo
fi
}


#######################################################################################
###########
# Checks  #
##########

#Check if running as root
if [[ "${UID}" -ne '0' ]]
then
	echo
	echo "This program must run with sudo" >&2
	echo
	exit 1
else
	user="$(who | cut -d ' ' -f1 )"
fi

#Check if argurments passeed
if [[ "${#}" -lt 1 ]]
then
	usage
fi

# Get User ID


########################################################################################
###########
# options #
###########

#set quiet mode to false
quiet_mode=false
nmap_scripts=true
web_scanning=true
nonstd_scanning=true

#parse options
hasI=0
while getopts 'i:qhnsw' OPTION "$@"
do
	case ${OPTION} in
		i)
			IP="$OPTARG"
			valid_ip
			hasI=1;
			;;
		h)
			usage
			;;
		q)
			quiet_mode=true
			;;
		n)
			nonstd_scanning=false
			;;
		s)
			nmap_scripts=false
			;;
		w)
			web_scanning=false
			;;
		*)
			echo 'Inavlid syntax'
			usage
			;;
	esac
done
if [[ $hasI -eq 0 ]]
then
		echo
    echo "-i option is mandatory."
		echo
    usage
fi


####################################################################################
########
# Main #
########

# Banner #
if [[ "${quiet_mode}" = false ]]
then
	echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
	echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
	echo '            **************************************************                 '
	echo '																																							 '
	echo '################################################################################'
	echo '####         #####         ####         #####         #####     #########   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####      ########   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####   #   #######   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####   ##   ######   ####'
	echo '####   ###   #####   ##########   ##########   #####   ####   ###   #####   ####'
	echo '####        ######         ####   ##########   #####   ####   ####   ####   ####'
	echo '####   ###   #####   ##########   ##########   #####   ####   #####   ###   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####   ######   ##   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####   #######   #   ####'
	echo '####   ####   ####   ##########   ##########   #####   ####   ########      ####'
	echo '####   ####   ####         ####         #####         #####   #########     ####'
	echo '################################################################################'
	echo '																																							 '
	echo '             **************************************************                '
	echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
	echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
fi

##############
# nmap scans #
##############

# set web port check #
open_21=false
open_80=false
open_443=false
open_445=false

#find last octet of machine
last_octet=$(echo "${IP}" | awk -F . '{print $4}')

#Directory for machines
#directory='/home/kali/htb/boxes'
read -p 'Enter Directory to save to : ' directory
read -p 'Enter Name of machine : ' box_name


# Set full file path
filepath="$directory/$box_name"
echo
echo '********** Checking if '${filepath}' exists. ************'

#check if file path exists
if test -d $filepath
	then
		echo "$filepath exists."
else
	echo "Creating $filepath"
	mkdir $filepath
	# Check if command successful
	if [[ $? -ne 0 ]]
	then
		echo 'Could not create directory.'
		exit 1
	else
		chown $user: $filepath
		echo "$filepath created."
	fi
fi


### Nmap Full Scan ###
# check if file path exists
if test -f "$filepath/full_scan"
then
	read -p 'Do you want new nmap full scan? y/n : ' scan_wanted
	check_scan_wanted
	echo
else
	nmap_full
fi


#create line separated list of ports
cat $filepath/full_scan | grep open | grep / | awk -F / '{print $1}' > "$filepath/open_ports"
chown $user: $filepath/open_ports

#Read in ports and append to variable
port_counter=0
echo
while read line
do
	ports="$ports,$line"
	#increment port_counter
	port_counter=$((port_counter + 1))
	#Check for web open_ports
	if  [[ $line -eq 21 ]]
	then
		open_21=true
	fi
	if [[ $line -eq 80 ]]
	then
		open_80=true
	fi
	if  [[ $line -eq 443 ]]
	then
		open_443=true
	fi
	if  [[ $line -eq 445 ]]
	then
		open_445=true
	fi
done < $filepath/open_ports

#remove leading comma
ports="$(echo $ports | cut -c2-)"


#Check if all ports closed
if [[ $port_counter -eq 0 ]]
then
		echo '********** Host is either down, or all ports are closed/filtered. ***********'
		echo
		echo 'nmap output: '
		echo
		cat $filepath/full_scan
		echo
		exit 1
else
		echo "$port_counter ports open: $ports"
		echo
fi


### Nmap Detailed Scan ###
# check if file path exists
if test -f "$filepath/detailed_scan"
then
	read -p 'Do you want new nmap detailed scan? y/n : ' dscan_wanted
	check_dscan_wanted
	echo
else
	nmap_detailed
fi
cat $filepath/detailed_scan | grep open | grep / | grep http | awk -F / '{print $1}' > "$filepath/http_ports"
chown $user: $filepath/http_ports

# UDP Scan

if test -f "$filepath/udp_scan"
then
	read -p 'Do you want new nmap udp scan? y/n : ' uscan_wanted
	check_uscan_wanted
	echo
else
	nmap_udp
fi

cat $filepath/udp_scan | grep open | grep / | awk -F / '{print $1}' > "$filepath/open_udp_ports"
chown $user: $filepath/open_udp_ports


udp_port_counter=0
while read line
do
	uports="$uports,$line"
	#increment port_counter
	udp_port_counter=$((udp_port_counter + 1))
	#Check for web open_ports
done < $filepath/open_udp_ports

#remove leading comma
uports="$(echo $uports | cut -c2-)"


#Check if all ports closed
if [[ $udp_port_counter -eq 0 ]]
then
		echo '********** All UDP ports closed. ***********'
		echo
		echo 'nmap output: '
		echo
		udscan_wanted=n
else
		echo "$udp_port_counter UDP ports open: $uports"
		echo
		udscan_wanted=y
fi

if test -f "$filepath/udp_detailed_scan"
then
	read -p 'Do you want new nmap UDP detailed scan? y/n : ' udscan_wanted
	check_udscan_wanted
	echo
else
	check_udscan_wanted
fi


#############
# Web Scans #
#############

# Copy links on HTTP page
if [[ $open_80 == true ]] || [[ $open_443 == true ]]
then
	echo '********** Robots.txt *********' > $filepath/robots.txt
fi

if [[ $open_80 == true ]]
then
	robots_url="http://$IP/robots.txt"
	http=true
	check_skip_web
fi

# Copy links on HTTPS page
if [[ "$open_443" == true ]]
then
	robots_url="https://$IP/robots.txt"
	http=false
	check_skip_web
fi

# check for web http_ports
http_port_counter=0
nonstandard_http_found=false
echo

if test -f "$filepath/nonstd_http"
then
	rm $filepath/nonstd_http
fi

while read line
do
	#Check for if non standard http ports found
	if  [[ $line -ne 80 ]] && [[ $line -ne 443 ]]
	then
		nonstandard_http_found=true
		echo "$line" >> $filepath/nonstd_http
		#increment port_counte
		http_port_counter=$((port_counter + 1))
	fi
done < $filepath/http_ports

if test -f "$filepath/nonstd_http"
then
	chown $user: $filepath/nonstd_http
fi

if [[ $http_port_counter -ne 0 ]]
then
		echo
		echo 'Non-standard HTTP ports found '
		echo
		echo > $filepath/dirb_nonstd
		chown $user: $filepath/dirb_nonstd
		while read line
		do {
			nonstand_http_scan "$line"
		} < /dev/null
	  done < $filepath/nonstd_http
fi


####################
# nmap NSE scritps #
####################
if [[ "$open_445" == true ]]
then
	smb_enum
fi

if [[ "$open_21" == true ]]
then
	ftp_enum
fi




echo
echo
echo "*********** RECON of $IP Completed!! **********"
echo "      *******************************************   "
echo "             ****************************          "
echo "                   ****************                "
echo
echo '                     GET HACKED!                  '
echo
echo
echo 'Thank you for choosing RECON for all your nefarious needs!!!'
echo
echo
# Exit Code
exit 0
