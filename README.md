Recon.sh 

This script will perform full enumeration scanning of host

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

sudo recon.sh -i <IP Address> <options>

options:

-h Display help menu

-i <IP address> IP address to scan
  
-n Skip non-std web scans

-q Quiet mode

-w skip web scans
  
 
