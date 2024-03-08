#!/bin/bash

if ! grep "ogstun" /proc/net/dev > /dev/null; then
    ip tuntap add name ogstun mode tun
fi 
ip addr del 10.45.0.1/16 dev ogstun 2> /dev/null
ip addr add 10.45.0.1/16 dev ogstun
ip addr del 2001:db8:cafe::1/48 dev ogstun 2> /dev/null
ip addr add 2001:db8:cafe::1/48 dev ogstun
ip link set ogstun up

sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE

# Prevent UE from connecting to UPF host
iptables -I INPUT -i ogstun -j ACCEPT
iptables -I INPUT -s 10.45.0.0/16 -j DROP

systemctl restart open5gs-upfd
