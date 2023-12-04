#!/bin/bash

docker run --privileged --name dind --rm -d docker:dind
docker exec -it dind /bin/sh

docker version