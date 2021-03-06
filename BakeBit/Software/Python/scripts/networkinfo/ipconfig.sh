#!/bin/bash

#Displays IP address, subnet mask, default gateway, DNS servers, speed, duplex, DHCP server IP address and name 
ACTIVEIP=$(ip a | grep "eth0" | grep "inet" | cut -d '/' -f1 | cut -d ' ' -f6)
SUBNET=$(ip a | grep "eth0" | grep "inet" | cut -d ' ' -f6 | tail -c 4)
LEASEDIPISUSED=$(grep "$ACTIVEIP" /var/lib/dhcp/dhclient.eth0.leases)
ETH0ISUP=$(/sbin/ifconfig eth0 | grep "RUNNING")
DHCPENABLED=$(grep -i "eth0" /etc/network/interfaces | grep "dhcp" | grep -v "#")
DHCPSRVNAME=$(grep -A 13 'interface "eth0"' /var/lib/dhcp/dhclient.eth0.leases | tail -13 | grep -B 1 -A 10 "$ACTIVEIP" | grep "server-name" | cut -d '"' -f2)
DHCPSRVADDR=$(grep -A 13 'interface "eth0"' /var/lib/dhcp/dhclient.eth0.leases | tail -13 | grep -B 1 -A 10 "$ACTIVEIP" | grep "dhcp-server-identifier" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
DOMAINNAME=$(grep -A 13 'interface "eth0"' /var/lib/dhcp/dhclient.eth0.leases | tail -13 | grep -B 1 -A 10 "$ACTIVEIP" | grep "domain-name " | cut -d '"' -f2)
DEFAULTGW=$(/sbin/route -n | grep G | grep eth0 | cut -d ' ' -f 10)
SPEED=$(sudo ethtool eth0 | grep -q "Link detected: yes" && sudo ethtool eth0 | grep "Speed" | sed 's/....$//' | cut -d ' ' -f2  || echo "Disconnected")
DUPLEX=$(sudo ethtool eth0 | grep -q "Link detected: yes" && sudo ethtool eth0 | grep "Duplex" | cut -d ' ' -f 2 || echo "Disconnected")
DNSSERVERS=$(sudo cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f2)

if [ "$ETH0ISUP" ]; then
    #IP address
    echo "IP: $ACTIVEIP"

    #Subnet
    echo "Subnet: $SUBNET"

    #Default gateway
    echo "DG: $DEFAULTGW"

    #DNS servers
    for n in $DNSSERVERS; do
        echo "DNS: $n"
    done

    #DHCP server info
    if [[ "$LEASEDIPISUSED" ]] && [[ "$DHCPENABLED" ]] && [[ "$ACTIVEIP" ]]; then
        if [[ "$DHCPSRVNAME" ]] && [[ "$LEASEDIPISUSED" ]]; then
            echo "DHCP server name: $DHCPSRVNAME"
        fi
        if [[ "$DHCPSRVADDR" ]] && [[ "$LEASEDIPISUSED" ]] && [[ "$ACTIVEIP" ]]; then
            echo "DHCP server address: $DHCPSRVADDR"
        fi
        if [[ "$DOMAINNAME" ]] && [[ "$LEASEDIPISUSED" ]] && [[ "$ACTIVEIP" ]]; then
            echo "Domain: $DOMAINNAME"
        fi
    else
        echo "No DHCP server used"
    fi

    #Speed
    echo "Speed: $SPEED"

    #Duplex
    echo "Duplex: $DUPLEX"

else
    echo "eth0 is down"
fi
