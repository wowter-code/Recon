#!/bin/bash

#Add live unique IPs identified by Nessus/Nmap in a txt file. Place one per line.
#Add live ports extracted from Nessus/Nmap in a txt file. Place one per line. To reduce time please add ports that are related to WEB services (exclude well-known DNS, NTP etc.)

#Check argument number
if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]; then
	echo " "	
	echo -e "\x1B[01;32m[+]\x1B[0m Example for installing prerequisites: autorecon-ng.sh install"
	echo -e "\x1B[01;32m[+]\x1B[0m Example: autorecon-ng.sh <IPs_file> <Ports_file>"
	exit 1
fi

#Install prerequisites for the script
function install_prereq () {
	echo "Installing prerequisites ..."
	apt update; apt install golang -y
	go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
	go install github.com/projectdiscovery/httpx/cmd/httpx@latest
	go install github.com/sensepost/gowitness@latest
	go install github.com/jaeles-project/gospider@latest
	echo -e "\n\x1B[01;32m[+]\x1B[0m Installation Completed ..."
	exit 2
}

#Set initial variables
DATE=$(date | tr -s " " | sed 's/ /_/g')
IP=$1

if [ "$1" = "install" ]; then
	install_prereq
fi

#Set next variables
PORTS=`echo $(cat $2) | sed 's/ /,/g'`
mkdir output_$DATE

function run_test () {
	echo "Starting test ..."

	#Use httpx to find live websites on provided ports
	httpx -l $IP -tls-grab -probe -sc -title -server -ct -p $PORTS -o output_$DATE/httpx_sites.txt

	#Extract URLs with SUCCESS status
	cat output_$DATE/httpx_sites.txt | grep "SUCCESS" | cut -d " " -f 1 | tee output_$DATE/httpx_sites_success.txt

	#Store httpx results for SUCCESS status
	cat output_$DATE/httpx_sites.txt | grep "SUCCESS" | tee output_$DATE/httpx_sites_success_all_results.txt

	#Run Nuclei against identified URLs
	nuclei -update
	nuclei -update -ut
	nuclei -l output_$DATE/httpx_sites_success.txt -o output_$DATE/nuclei_scan_results.txt

	#Run Gowitness to get screenshots of the live URLs
	gowitness file -f output_$DATE/httpx_sites_success.txt -P output_$DATE/screenshots

	#Run Gospider to find URL resources that can be usefull
	gospider -S output_$DATE/httpx_sites_success.txt -o output_$DATE/gospider_results

	echo -e "\n\x1B[01;32m[+]\x1B[0m Scanning is Completed\! Review the results from output_$DATE directory."
}

if [[ $# -eq 2 ]]; then
	run_test
fi
