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

#!/usr/bin/env bash

show_no_rdns4=1  # Set to 1 to show IPv4 with no RDNS, 0 to hide
show_no_rdns6=1  # Set to 1 to show IPv6 with no RDNS, 0 to hide

# Define excluded IPs and RDNS entries

EXCLUDED_IPS=(
    "2006:320:2:17b::100"
    "192.168.1.1"
)

EXCLUDED_RDNS=(
    "example.com"
    "badhost.local"
)

IP_LIST=$(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1; ip -o -6 addr show | awk '{print $4}' | cut -d/ -f1)

echo "Generating, please wait..."

declare -A RDNS_CACHE
declare -a WITH_RDNS
declare -a WITHOUT_RDNS

for IP in $IP_LIST; do
    # Skip if IP is in the exclusion list
    if [[ " ${EXCLUDED_IPS[@]} " =~ " $IP " ]]; then
        continue
    fi

    RDNS=$(dig +short -x "$IP" 2>/dev/null)

    # Skip if RDNS is empty or in the exclusion list
    if [[ -n "$RDNS" ]] && [[ " ${EXCLUDED_RDNS[@]} " =~ " $RDNS " ]]; then
        continue
    fi

    if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        # IPv4: Skip if no RDNS and show_no_rdns4 is 0
        if [[ $show_no_rdns4 -eq 0 && -z "$RDNS" ]]; then
            continue
        fi
    else
        if [[ $show_no_rdns6 -eq 0 && -z "$RDNS" ]]; then
            continue
        fi
    fi

    RDNS_CACHE["$IP"]="$RDNS"

    FORMATTED_LINE=$(printf "%-25s -   %s" "$IP" "${RDNS:-(No RDNS)}")

    if [[ -n "$RDNS" ]]; then
        WITH_RDNS+=("$FORMATTED_LINE")
    else
        WITHOUT_RDNS+=("$FORMATTED_LINE")
    fi
done

OUTPUT_LIST=("${WITH_RDNS[@]}" "${WITHOUT_RDNS[@]}")

echo " "
echo "Listing IP addresses and RDNS (available vhosts):"
echo " "
for line in "${OUTPUT_LIST[@]}"; do
    echo "$line"
done | more
echo " "
