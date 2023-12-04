#!/bin/bash

read -rp "Enter registry [leave empty to use Docker Hub]: " registry
read -rp "Enter username: " username
read -rp "Enter image name [leave empty to use \"multiplatform_nginx\"]: " image_name

registry=${registry:-registry-1.docker.io}
image_name=${image_name:-multiplatform_nginx}

docker buildx build --platform linux/amd64,linux/arm64,linux/arm64/v8 -t ${registry}/${username}/${image_name}:latest --push .