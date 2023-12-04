#!/bin/bash

read -rp "Enter registry [leave empty to use Docker Hub]: " registry
read -rp "Enter username: " username
read -rp "Enter image name [leave empty to use \"multiplatform_nginx\"]: " image_name

registry=${registry:-registry-1.docker.io}
image_name=${image_name:-multiplatform_nginx}

docker run -d --rm -p 8084:80 --name ${image_name} ${registry}/${username}/${image_name}:latest