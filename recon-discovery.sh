#!/bin/bash

mkdir scan_output

#Install prereq for the script - Uncomment the following 5 lines if you need to install the tools
#apt update; apt install golang -y
#go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
#go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
#go install github.com/sensepost/gowitness@latest
#go install github.com/jaeles-project/gospider@latest

#Add live unique IPs identified by Nessus/Nmap in a file called live_IPs.txt. Place one per line.

#Add comma sepparted live ports extracted from Nessus/Nmap in a file called ports.txt. To reduce time please add ports that are related to WEB services (exclude well-known DNS, NTP etc.)
PORTS=`cat ports.txt`

#Use httpx to find live websites on provided ports
httpx -l live_IPs.txt -tls-grab -probe -sc -title -tech -server -ct -p $PORTS -o scan_output/httpx_sites.txt

#Extract URLs with SUCCESS status
cat scan_output/httpx_sites.txt | grep "SUCCESS" | cut -d " " -f 1 | tee scan_output/httpx_sites_success.txt

#Store httpx results for SUCCESS status
cat scan_output/httpx_sites.txt | grep "SUCCESS" | tee scan_output/httpx_sites_success_all_results.txt

#Run Nuclei against identified URLs
nuclei -l scan_output/httpx_sites_success.txt -o scan_output/nuclei_scan_results.txt

#Run Gowitness to get screenshots of the live URLs
gowitness file -f scan_output/httpx_sites_success.txt -P scan_output/screenshots

#Run Gospider to find URL resources that can be usefull
gospider -S scan_output/httpx_sites_success.txt -o scan_output/gospider_results

echo "Scanning is Completed\! Review the results from scan_output directory."
