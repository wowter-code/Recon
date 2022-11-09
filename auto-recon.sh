#!/bin/bash

echo "example auto-recon.sh <IPs_file> <Ports_file>"

DATE=$(date | tr -s " " | sed 's/ /_/g')

mkdir output_$DATE

#Install prereq for the script - Uncomment the following 5 lines if you need to install the tools
#apt update; apt install golang -y
#go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
#go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
#go install github.com/sensepost/gowitness@latest
#go install github.com/jaeles-project/gospider@latest
#Add live unique IPs identified by Nessus/Nmap in a txt file. Place one per line.
#Add live ports extracted from Nessus/Nmap in a txt file. Place one per line. To reduce time please add ports that are related to WEB services (exclude well-known DNS, NTP etc.)


PORTS=`echo $(cat $2) | sed 's/ /,/g'`

#Use httpx to find live websites on provided ports
httpx -l $1 -tls-grab -probe -sc -title -server -ct -p $PORTS -o output_$DATE/httpx_sites.txt

#Extract URLs with SUCCESS status
cat output_$DATE/httpx_sites.txt | grep "SUCCESS" | cut -d " " -f 1 | tee output_$DATE/httpx_sites_success.txt

#Store httpx results for SUCCESS status
cat output_$DATE/httpx_sites.txt | grep "SUCCESS" | tee output_$DATE/httpx_sites_success_all_results.txt

#Run Nuclei against identified URLs
nuclei -l output_$DATE/httpx_sites_success.txt -o output_$DATE/nuclei_scan_results.txt

#Run Gowitness to get screenshots of the live URLs
gowitness file -f output_$DATE/httpx_sites_success.txt -P output_$DATE/screenshots

#Run Gospider to find URL resources that can be usefull
gospider -S output_$DATE/httpx_sites_success.txt -o output_$DATE/gospider_results

echo "Scanning is Completed\! Review the results from output_$DATE directory."
