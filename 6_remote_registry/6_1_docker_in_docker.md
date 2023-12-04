# Docker In Docker

Docker in Docker (also known as dind) is,
as the name implies, running Docker on top of a Docker container.
Controlling containers from a Docker container is not a particular
use case but is often necessary to run CI tools such as Jenkins on top
of a Docker container. It is not a specific use case but is often needed
to run CI tools such as Jenkins on Docker containers.

1.) Docker in Docker Using **DIND**

> This approach requires running container in 
> privileged mode by passing flag --privileged

```shell
docker run --privileged --name dind --rm -d docker:dind
docker exec -it dind /bin/sh
```

This container has a docker engine installed in it, which is
isolated from docker engine on your host machine.

Try version of docker installed inside container:
```shell
docker version
```

Pull some image inside the container, then exit it and get list if images
on the host machine: this image is only installed inside the container!

```shell
docker pull busybox
docker image ls
exit
docker image ls | grep busybox
```
The output should be empty

Stop docker container: ```docker stop dind```

2.) Docker in Docker Using **DOOD** (bypassing of docker.sock)

In this example we just bypass a docker.sock unix socket to our newly created 
container and open it via /bin/sh

```shell
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock docker /bin/sh
```

Run nginx container from inside this container:
```shell
docker run -p 8080:80 -d --name nginx-from-inside-dood nginx
```

If we try to get all the containers running, we will get all containers running on
the host machine (and also our container and nginx)
```shell
docker ps
```

Exit the shell, container will be automatically removed
```shell
exit
```
