#!/bin/bash

docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock docker /bin/sh

docker run -p 8080:80 -d --name nginx-from-inside-dood nginx

docker ps

exit
