#!/usr/bin/env bash
# vhosts - A Bash script to list all assigned IP addresses and their Reverse DNS (RDNS)
#
# Description:
# This script retrieves all IPv4 and IPv6 addresses assigned to the system,
# performs a reverse DNS lookup for each, and prints the results.
# It also allows exclusion of specific IPs and RDNS entries from the output.
#
# Usage:
# 1. Save the script as /usr/local/bin/vhosts
# 2. Make it executable: chmod +x /usr/local/bin/vhosts
# 3. Run the script: ./vhosts
#
# Configuration:
# Modify the EXCLUDED_IPS and EXCLUDED_RDNS arrays to filter out unwanted entries.
#
# Dependencies:
# - ip (from iproute2)
# - dig (from dnsutils)
#
# Author: Richard Zeamp (zeamp.com)

# Define excluded IPs and RDNS entries
# Define excluded IPs and RDNS entries that you want to hide from this list
# such as your private hosts or any other entry.

EXCLUDED_IPS=(
    "2006:320:2:17b::100"
    "192.168.1.1"
)
EXCLUDED_RDNS=(
    "example.com"
    "badhost.local"
)

# Get all assigned IP addresses (IPv4 and IPv6)
IP_LIST=$(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1; ip -o -6 addr show | awk '{print $4}' | cut -d/ -f1)

echo "Listing IP addresses and RDNS (excluding specified entries):"

declare -A RDNS_CACHE

for IP in $IP_LIST; do
    # Skip if IP is in the exclusion list
    if [[ " ${EXCLUDED_IPS[@]} " =~ " $IP " ]]; then
        continue
    fi
    
    # Get RDNS
    RDNS=$(dig +short -x "$IP" 2>/dev/null)
    
    # Skip if RDNS is empty or in the exclusion list
    if [[ -n "$RDNS" ]] && [[ " ${EXCLUDED_RDNS[@]} " =~ " $RDNS " ]]; then
        continue
    fi
    
    # Cache and print
    echo "$IP - ${RDNS:-(No RDNS)}"
done
