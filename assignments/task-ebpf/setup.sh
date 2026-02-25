#!/bin/bash

ip netns add ns1  # create namespace
ip link add veth0 type veth peer name veth1 # create veth pair
ip link set veth1 netns ns1  # Move one end of veth to namespace

# Set address to namespace interface
ip netns exec ns1 ip addr add 192.168.76.2/24 dev veth1
ip netns exec ns1 ip link set veth1 up

# Set address to root interface
ip addr add 192.168.76.1/24 dev veth0
ip link set veth0 up

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Set up NAT masquarading to outgoing traffic
# (Change the outgoing interface ("ethp0s5") accordingly based on your system, if needed)
nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100\; }
nft add rule ip nat postrouting ip saddr 192.168.76.0/24 oif "enp0s5" masquerade

# Set up default route to ns1
ip netns exec ns1 ip route add default via 192.168.76.1

# Set up nameserver to ns1
mkdir -p /etc/netns/ns1
bash -c 'echo "nameserver 8.8.8.8" > /etc/netns/ns1/resolv.conf'
