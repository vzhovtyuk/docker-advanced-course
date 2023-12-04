# Docker multi-platform images

Docker images can support multiple platforms, which means that a single image may contain variants for different architectures, 
and sometimes for different operating systems, such as Windows.

When we run an image with multi-platform support, Docker automatically selects the image that matches your OS and architecture.

1.) Build strategies

We can build multi-platform images using three different strategies, depending on use case:

1. Using the QEMU emulation support in the kernel
2. Building on multiple native nodes using the same builder instance
3. Using a stage in Dockerfile to cross-compile to different architectures

Since we only have one machine with a strict processor architecture, we choose the first option.

2.) QEMU

All we need is Docker to start building multi-platform images.
Worth noting that emulation with QEMU can be much slower than native builds, 
especially for compute-heavy tasks like compilation and compression or decompression.

For QEMU binaries registered with ```binfmt_misc``` on the host OS to work transparently inside containers, they must be statically compiled and registered with the ```fix_binary flag```.
This requires a kernel version 4.8 or later, and binfmt-support version 2.1.7 or later.

We can verify the registration by checking if ```F``` is among the flags in ```/proc/sys/fs/binfmt_misc/qemu-*```.

To install and verify, let's run:

```shell
docker run --privileged --rm tonistiigi/binfmt --install all
ls -l /proc/sys/fs/binfmt_misc/
```
This enables the host machine to execute binaries built for different architectures transparently.

3.) Buildx

```buildx``` is a Docker CLI plugin for extended build capabilities with ```BuildKit```, 
whereas ```BuildKit``` is a toolkit for converting source code to build artifacts in an efficient, expressive and repeatable manner.

To build multi-platform images, we need to install buildx plugin or ensure that it is already installed:

```shell
sudo apt list --installed docker-buildx-plugin
docker buildx version
```

if ```buildx``` is not installed, run:

```shell
sudo apt-get install docker-buildx-plugin
```

As of Docker Engine 23.0 and Docker Desktop 4.19, Buildx is the default build client.

4.) Create a builder

Run the ```docker buildx ls``` command to list the existing builders:

```shell
docker buildx ls
```

This displays the default builtin driver, that uses the BuildKit server components built directly into the docker engine, also known as the ```docker driver```.

Create a new builder using the ```docker-container driver``` which gives us access to more complex features like multi-platform builds:

```shell
docker buildx create --name custom_builder --driver=docker-container --bootstrap --use
```

Now listing the existing builders again, we can see our new builder is registered:

```shell
docker buildx ls
```

5.) Create a multi-platform image 

Let's test the workflow to ensure we can build, push, and run multi-platform images.

We are going to use a simple example Dockerfile, build a couple of image variants, and push them to Docker Hub.

Pushing to the registry is necessary because build results only remain in the build cache. 
We cannot store the image locally and run it due to multi-platform restrictions.

To push an image to a registry, first login to Docker Hub and then add the **--push** flag to the build command.

If you prefer another image registry, you can use it instead of Docker Hub.

Login to Docker Hub:
```shell
docker login
```

The following example uses a simple Dockerfile to build an Nginx image for multiple architectures:

```Dockerfile```
```dockerfile
FROM nginx:1.25.3-alpine
COPY index.html /usr/share/nginx/html/
RUN ARCH=$(uname -a) && \
    sed -i "s|Architecture|$ARCH|g" /usr/share/nginx/html/index.html
EXPOSE 80
```

**Important!** The base image must support multi-platform builds. 
In the example above, we use the ```nginx:1.25.3-alpine``` image, which supports multi-platform builds.

To verify that the base image supports multi-platform builds, run the following command:

```shell
docker buildx imagetools inspect nginx:1.25.3-alpine
```

Build the Dockerfile with buildx, passing the list of architectures to build for and pushing the result to Docker Hub.
Change the registry and repository to match yours:

```shell
docker buildx build --platform linux/amd64,linux/arm64,linux/arm64/v8 -t registry-1.docker.io/artebomba/multiplatform_nginx:latest --push ./src/
```

Let's run a container from the image we just built:

```shell
docker run -d --rm -p 8084:80 --name multiplatform_nginx registry-1.docker.io/artebomba/multiplatform_nginx:latest
```
To check the index page, open http://localhost:8084 in your browser.

Inspect the image to see the supported platforms:

```shell
docker buildx imagetools inspect registry-1.docker.io/artebomba/multiplatform_nginx:latest
```

Inspect the local image to see the supported platforms:

```shell
docker image inspect --format='{{ json .Architecture }}' registry-1.docker.io/artebomba/multiplatform_nginx:latest
```

Docker automatically selects the image that matches your OS and architecture, that's why we see only one architecture.

From now, we can use this image to run a container on Intel laptops, Amazon EC2 Graviton instances, Raspberry Pis, 
and on other architectures. Docker pulls the correct image for the current architecture, 
so Raspberry PIs run the 32-bit Arm version and EC2 Graviton instances run 64-bit Arm.