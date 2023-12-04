#!/bin/bash

read -rp "Enter registry [leave empty to use Docker Hub]: " registry
read -rp "Enter username: " username
read -s -rp "Enter Docker password: " password

registry=${registry:-registry-1.docker.io}

# Login to Docker
docker login -u "$username" -p "$password" "$registry"