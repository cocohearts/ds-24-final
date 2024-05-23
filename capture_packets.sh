#!/bin/bash

# Clear the logs (empty the file)
> tcpdump-logs.csv

# Function to capture packets and append to the CSV file
capture_packets() {
    sudo tcpdump -i en0 -tttt | awk '
    BEGIN {
        print "Date,Timestamp,Source,Destination,Details"
    }
    {
        # Get the current IP address using ifconfig
        cmd = "ifconfig | grep \x22inet.*broadcast\x22 | awk \x27{print $2}\x27"
        cmd | getline CURRENT_IP
        close(cmd)

        # Get the current hostname
        cmd = "hostname"
        cmd | getline HOSTNAME
        close(cmd)

        date = $1
        timestamp = $2
        protocol = $3

        if (protocol == "IP" || protocol == "IP6") {
            source = $4
            destination = $6
            # Remove trailing colon from destination address
            destination = substr(destination, 1, length(destination) - 1)
            details = ""

            for (i = 7; i <= NF; i++) {
                details = details $i " "
            }

            # Check if source or destination starts with the hostname or matches the current IP
            if (index(source, HOSTNAME) == 1 || index(destination, HOSTNAME) == 1 || index(source, CURRENT_IP) == 1 || index(destination, CURRENT_IP) == 1) {
                printf "%s,%s,%s,%s,%s\n", date, timestamp, source, destination, details >> "tcpdump-logs.csv"
            }
        }
    }'
}

# Run the packet capture in the background
capture_packets &

# Display the last 10 lines of the CSV file dynamically along with the total number of lines and current IP and hostname
while true; do
    clear
    # Get the current IP address using ifconfig
    CURRENT_IP=$(ifconfig | grep "inet.*broadcast" | awk '{print $2}')
    # Get the current hostname
    HOSTNAME=$(hostname)
    echo "Current IP: $CURRENT_IP"
    echo "Hostname: $HOSTNAME"
    echo "Last 10 lines of tcpdump-logs.csv:"
    tail -n 10 tcpdump-logs.csv
    echo ""
    echo "Total number of lines in tcpdump-logs.csv:"
    wc -l < tcpdump-logs.csv
    sleep 4
done
