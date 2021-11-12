Recon.sh 

This script will perform full enumeration scanning of host

** Copy medium.txt to ~/  for GoBuster to work, or modify the code. **

includes:

nmap full scan TCP, UDP<br />
nmap detailed scans of found ports TCP, UDP<br />
web scanning with nikto, dirb, gobuster<br />
listing links found on main page<br />
copy robots.txt<br />
identification of nonstandard http ports <br />
web page brute force of nonstd http ports<br />
nmap NSE scripts against: SMB, FTP <br />

Usage:

sudo recon.sh -i \<IP Address\> \<options\>

options:

	-a Add host to /etc/hosts file, no further enum
	-h Display this help menu
	-i <IP>	Specify IP address to scan
	-n Skip non-std web scans
	-r Restore /etc/hosts file from backup
	-s Skip nmap scripts
	-q Specify quiet mode. (Runs without Banner).
	-w Skip web scans
  
 
