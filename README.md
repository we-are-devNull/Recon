Recon.sh 

This script will perform full enumeration scanning of host

** Copy medium.txt to ~/  for GoBuster to work, or modify the code. **

includes:

nmap full scan TCP, UDP
nmap detailed scans of found ports TCP, UDP
web scanning with nikto, dirb, gobuster
listing links found on main page
copy robots.txt
identification of nonstandard http ports 
web page brute force of nonstd http ports
nmap NSE scripts against: SMB, FTP 

Usage:

sudo recon.sh -i \<IP Address\> \<options\>

options:

	-h Display this help menu
	-i <IP>	Specify IP address to scan
	-n Skip non-std web scans
	-r Restore /etc/hosts file from backup
	-s Skip nmap scripts
	-q Specify quiet mode. (Runs without Banner).
	-w Skip web scans
  
 
