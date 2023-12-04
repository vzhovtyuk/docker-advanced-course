#!/bin/bash

# Initialize Docker Swarm (if not already initialized)
docker swarm init

# Create an overlay network
docker network create --driver overlay my_overlay_network
