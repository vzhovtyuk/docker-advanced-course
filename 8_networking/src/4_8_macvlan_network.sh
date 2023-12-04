#!/bin/bash
# Create a Macvlan network
docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 my_macvlan_network

# Run a container on the Macvlan network
docker run -d --name container_macvlan --network my_macvlan_network nginx
