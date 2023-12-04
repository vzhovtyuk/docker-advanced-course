# Podman

[Podman](https://podman.io/) is a daemonless, open source, Linux native tool designed to make it easy to find, run, build, share and deploy applications using Open Containers Initiative (OCI) Containers and Container Images.

1.) Podman setup

https://podman.io/docs/installation

```shell
# Ubuntu 20.10 and newer
 sudo apt-get update
 sudo apt-get -y install podman
```

2.) Podman start
```shell
podman machine init
podman machine start
```

3.) Podman info
```shell
podman info
```

4.) Podman image search
```shell
podman search nginx --filter=is-official
```

5.) Podman pull nginx image
```shell
podman pull docker.io/library/nginx
```

6.) Podman run nginx

```shell
podman run -d -p 8081:80 --name webserver nginx
```


