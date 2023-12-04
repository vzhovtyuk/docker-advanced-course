#!/bin/bash

docker pull busybox
docker image ls
exit
docker image ls | grep busybox
docker stop dind