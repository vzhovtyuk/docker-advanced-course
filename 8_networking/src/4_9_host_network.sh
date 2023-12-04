#!/bin/bash

# Run a container using the host network
docker run -d --name container_host_network --network host nginx
