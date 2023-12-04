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
