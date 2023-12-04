# Docker Multistage builds

1.) Create a **Dockerfile**

Create a file with name **Dockerfile** (without extension) inside **spring-petclinic** directory
```shell
touch Dockerfile
```

Put this script inside the **Dockerfile** file

```dockerfile
FROM maven:3-openjdk-17 AS builder

ENV USER_HOME_DIR "/home/ubuntu"

# an environment variable used by the shell scripts that launch the Java Virtual Machine (JVM) that runs Maven
ENV MAVEN_OPTS "-Dmaven.repo.local=$USER_HOME_DIR/.m2/repository -Djava.awt.headless=true"
ENV MAVEN_CLI_OPTS "--batch-mode --errors --fail-at-end"
WORKDIR /build
COPY . ./

RUN --mount=type=cache,target=$USER_HOME_DIR/.m2/repository \
    mvn $MAVEN_CLI_OPTS clean package -DskipTests=true

FROM bellsoft/liberica-openjdk-alpine:17
RUN apk add --no-cache bash curl netcat-openbsd
COPY --from=builder /build/target/*.jar /build/result.jar
EXPOSE 8080
CMD java -jar /build/result.jar
```

2.) Build a docker image: run this command inside **spring-petclinic** directory

```shell
cd spring-petclinic
docker build . --tag petclinic
```

This command will build an image from **Dockerfile** file inside this directory and with name **petclinic:latest**
> **Hint:** --tag (-t) flag gives a specified name to your image.
> It is a good practice to use it always when you build an image

3.) Run container

```shell
docker run --name petclinic -p 9000:8080 --rm petclinic
```

> **Hint:** Use flag ```--rm``` for ```docker run command``` to automatically remove the container after it is stopped

4.) Stop container using Ctrl+C, for example, - it will be automatically removed
