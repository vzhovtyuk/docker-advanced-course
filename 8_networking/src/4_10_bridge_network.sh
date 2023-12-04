#!/bin/bash

# Create a bridge network
docker network create my_bridge_network

# Run a container with port mapping
docker run -d --name container_port_mapping --network my_bridge_network -p 8080:80 nginx
