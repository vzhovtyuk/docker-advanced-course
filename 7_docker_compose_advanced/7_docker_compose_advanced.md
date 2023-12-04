# Docker Compose advanced features

### 0.) Preparations

Create folder `petclinic` and clone repositories into it: 
* sources https://github.com/spring-petclinic/spring-petclinic-microservices
* configuration repository https://github.com/spring-petclinic/spring-petclinic-microservices-config

This microservice application uses config-server pattern which requires 
either a `remote git repository` or `folder` with spring boot configuration files.
We need to change some behavior, that is why we will use config server with 
`native` spring boot profile and reads configuration from locally hosted folder.

To use a database in docker create a file `application-mysql.yml`
inside a spring-petclinic-microservices-config folder(it will be used if `mysql` spring boot profile enabled):

```yaml
spring:
  datasource:
    url: ${MYSQL_URL}
    username: ${MYSQL_USER}
    password: ${MYSQL_PASSWORD}
  sql:
    init:
      mode: never
```

Also put an `init.sql` script for database into `petclinic` folder

### 1.) docker-compose.yaml most simple setup 

Here is our docker compose configuration. The one from spring petclinic repo is 
old-versioned and really out of date. Put this into `docker-compose.yaml` config file
This is first version of `docker-compose.yaml` file: 
* it contains: 
  * environment variables
  * healthchecks
  * resource limitations
  * port forwarding
  * volumes
* drawbacks:
  * many similar blocks of code (no anchors)
  * environment variables are hardcoded (no env-files)
  * difficult to start up a set of services conditionally (no profiles)

```yaml
version: '3.9'

services:

  config-server:
    image: springcommunity/spring-petclinic-config-server
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: native
      GIT_REPO: /config_folder
    volumes:
      - ../petclinic/spring-petclinic-microservices-config:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      interval: 5s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  discovery-server:
    image: springcommunity/spring-petclinic-discovery-server
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      interval: 5s
      timeout: 10s
      retries: 3
      start_period: 15s
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  customers-service:
    image: springcommunity/spring-petclinic-customers-service
    container_name: customers-service
    environment:
      SPRING_PROFILES_ACTIVE: docker,mysql
      MYSQL_URL: jdbc:mysql://petclinicdb/petclinic?useSSL=false
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
    depends_on:
      config-server:
        condition: service_healthy
      discovery-server:
        condition: service_healthy
      petclinicdb:
        condition: service_healthy

  visits-service:
    image: springcommunity/spring-petclinic-visits-service
    container_name: visits-service
    environment:
      SPRING_PROFILES_ACTIVE: docker,mysql
      MYSQL_URL: jdbc:mysql://petclinicdb/petclinic?useSSL=false
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
    depends_on:
      config-server:
        condition: service_healthy
      discovery-server:
        condition: service_healthy
      petclinicdb:
        condition: service_healthy

  vets-service:
    image: springcommunity/spring-petclinic-vets-service
    container_name: vets-service
    environment:
      SPRING_PROFILES_ACTIVE: docker,mysql
      MYSQL_URL: jdbc:mysql://petclinicdb/petclinic?useSSL=false
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
    depends_on:
      config-server:
        condition: service_healthy
      discovery-server:
        condition: service_healthy
      petclinicdb:
        condition: service_healthy

  api-gateway:
    image: springcommunity/spring-petclinic-api-gateway
    container_name: api-gateway
    depends_on:
      config-server:
        condition: service_healthy
      discovery-server:
        condition: service_healthy
    ports:
      - 8080:8080

  admin-server:
    image: springcommunity/spring-petclinic-admin-server
    container_name: admin-server
    depends_on:
      config-server:
        condition: service_healthy
      discovery-server:
        condition: service_healthy
    ports:
      - 9090:9090

  petclinicdb:
    container_name: database
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password # just needed for root user
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
      MYSQL_DATABASE: petclinic
    volumes:
      - ../dbdata:/var/lib/mysql
      - ../petclinic/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      interval: 5s
      timeout: 2s
      retries: 5
      start_period: 10s
```

Start petclinic
```shell
cd petclinic/spring-petclinic-microservices
docker compose up -d
```

### 2.) anchors and aliases: "do not repeat yourself"

`Extensions` can be used to make your Compose file more efficient and easier 
to maintain. `Extensions` can also be used with `anchors` and `aliases`.
Use the prefix `x`- as a top-level element to modularize configurations that 
you want to reuse. 

> Compose ignores any fields that start with `x-`, this is the sole 
exception where Compose silently ignores unrecognized fields.

Change docker-compose.yaml file to this one:

```yaml
version: '3.9'

x-depends-on-config-server-and-eureka: &depends-on-config-server-and-eureka
    config-server:
      condition: service_healthy
    discovery-server:
      condition: service_healthy

x-spring-profiles: &spring-profiles
  SPRING_PROFILES_ACTIVE: docker,mysql

x-database-connection: &database-connection
  MYSQL_URL: jdbc:mysql://petclinicdb/petclinic?useSSL=false
  MYSQL_USER: petclinic
  MYSQL_PASSWORD: petclinic

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

services:

  config-server:
    image: springcommunity/spring-petclinic-config-server
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: native
      GIT_REPO: /config_folder
    volumes:
      - ../petclinic/spring-petclinic-microservices-config:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  discovery-server:
    image: springcommunity/spring-petclinic-discovery-server
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  customers-service:
    image: springcommunity/spring-petclinic-customers-service
    container_name: customers-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  visits-service:
    image: springcommunity/spring-petclinic-visits-service
    container_name: visits-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  vets-service:
    image: springcommunity/spring-petclinic-vets-service
    container_name: vets-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  api-gateway:
    image: springcommunity/spring-petclinic-api-gateway
    container_name: api-gateway
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 8080:8080

  admin-server:
    image: springcommunity/spring-petclinic-admin-server
    container_name: admin-server
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 9090:9090

  petclinicdb:
    container_name: database
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: password # just needed for root user
      MYSQL_USER: petclinic
      MYSQL_PASSWORD: petclinic
      MYSQL_DATABASE: petclinic
    volumes:
      - ../dbdata:/var/lib/mysql
      - ../petclinic/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      <<: *healthcheck-config
```

* it contains:
  * ...
  * anchors and aliases which improve the code reuse
* drawbacks:
  * environment variables are hardcoded (no env-files)
  * difficult to start up a set of services conditionally (no profiles)
>  **HINT!**
> 
> By the way, you can see the file version of your `docker-compose.yaml` file with
> all the interpolations and templating performed by executing command:
> `docker compose config` (it even **does not** require docker compose cluster to be already running)

Start petclinic
```shell
cd petclinic/spring-petclinic-microservices
docker compose up -d
```

### 3.) env files: keep your docker-compose.yaml unchanged
Let's move all the variables to `.env` file in sake of decomposition. 
Docker compose uses file with name `.env` like env file by default, but you can 
set the separate file using command:

```shell
docker compose --env-file <any-file-name> up -d
```

Create file `.env` in the same folder as `docker-compose.yaml` file.
```shell
# global spring configuration
SPRING_PROFILES_ACTIVE=docker,mysql
MYSQL_URL=jdbc:mysql://petclinicdb/petclinic?useSSL=false
MYSQL_USER=petclinic
MYSQL_PASSWORD=petclinic

# config-server configuration
CONFIG_SERVER_SPRING_PROFILES_ACTIVE=native
CONFIG_SERVER_GIT_REPO="/config_folder"

# petclinicdb configuration
PETCLINICDB_MYSQL_ROOT_PASSWORD=password # just needed for root user
PETCLINICDB_MYSQL_USER=petclinic
PETCLINICDB_MYSQL_PASSWORD=petclinic
PETCLINICDB_MYSQL_DATABASE=petclinic

# volumes
CONFIG_SERVER_CONFIG_FOLDER_LOCATION_VOLUME="../petclinic/spring-petclinic-microservices-config"
PETCLINICDB_DATABASE_VOLUME="../dbdata"
PETCLINICDB_INIT_SCRIPT_VOLUME="../petclinic/init.sql"

# images
MYSQL_IMAGE=mysql:8.0
CONFIG_SERVER_IMAGE=springcommunity/spring-petclinic-config-server
DISCOVERY_SERVER_IMAGE=springcommunity/spring-petclinic-discovery-server
CUSTOMERS_SERVICE_IMAGE=springcommunity/spring-petclinic-customers-service
VISITS_SERVICE_IMAGE=springcommunity/spring-petclinic-visits-service
VETS_SERVICE_IMAGE=springcommunity/spring-petclinic-vets-service
API_GATEWAY_IMAGE=springcommunity/spring-petclinic-api-gateway
ADMIN_SERVER_IMAGE=springcommunity/spring-petclinic-admin-server
```

Change your `docker-compose.yaml` file appropriately, as you might see, it became more configurable
```yaml
version: '3.9'

x-depends-on-config-server-and-eureka: &depends-on-config-server-and-eureka
    config-server:
      condition: service_healthy
    discovery-server:
      condition: service_healthy

x-spring-profiles: &spring-profiles
  SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE}

x-database-connection: &database-connection
  MYSQL_URL: ${MYSQL_URL}
  MYSQL_USER: ${MYSQL_USER}
  MYSQL_PASSWORD: ${MYSQL_PASSWORD}

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

services:

  config-server:
    image: ${CONFIG_SERVER_IMAGE}
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: ${CONFIG_SERVER_SPRING_PROFILES_ACTIVE}
      GIT_REPO: ${CONFIG_SERVER_GIT_REPO}
    volumes:
      - ${CONFIG_SERVER_CONFIG_FOLDER_LOCATION_VOLUME}:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  discovery-server:
    image: ${DISCOVERY_SERVER_IMAGE}
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'

  customers-service:
    image: ${CUSTOMERS_SERVICE_IMAGE}
    container_name: customers-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  visits-service:
    image: ${VISITS_SERVICE_IMAGE}
    container_name: visits-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  vets-service:
    image: ${VETS_SERVICE_IMAGE}
    container_name: vets-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  api-gateway:
    image: ${API_GATEWAY_IMAGE}
    container_name: api-gateway
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 8080:8080

  admin-server:
    image: ${ADMIN_SERVER_IMAGE}
    container_name: admin-server
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 9090:9090

  petclinicdb:
    container_name: database
    image: ${MYSQL_IMAGE}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${PETCLINICDB_MYSQL_ROOT_PASSWORD} # just needed for root user
      MYSQL_USER: ${PETCLINICDB_MYSQL_USER}
      MYSQL_PASSWORD: ${PETCLINICDB_MYSQL_PASSWORD}
      MYSQL_DATABASE: ${PETCLINICDB_MYSQL_DATABASE}
    volumes:
      - ${PETCLINICDB_DATABASE_VOLUME}:/var/lib/mysql
      - ${PETCLINICDB_INIT_SCRIPT_VOLUME}:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      <<: *healthcheck-config
```

Start petclinic
```shell
cd petclinic/spring-petclinic-microservices
docker compose up -d
```

### 4.) profiles: start your services conditionally

With profiles you can define a set of active profiles so your Compose application 
model is adjusted for various usages and environments. 
The exact mechanism is implementation specific and may include command line flags, 
environment variables, etc.

You can run only some subset of services using profiles option:

`docker compose --profile <profile_name> up -d`

This will run only services which have `prod` profile.

You are also can enable several profiles:
`docker compose --profile <profile_name_1> --profile <profile_name_2> up -d`

```yaml
version: '3.9'

x-depends-on-config-server-and-eureka: &depends-on-config-server-and-eureka
    config-server:
      condition: service_healthy
    discovery-server:
      condition: service_healthy

x-spring-profiles: &spring-profiles
  SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE}

x-database-connection: &database-connection
  MYSQL_URL: ${MYSQL_URL}
  MYSQL_USER: ${MYSQL_USER}
  MYSQL_PASSWORD: ${MYSQL_PASSWORD}

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

services:

  config-server:
    image: ${CONFIG_SERVER_IMAGE}
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: ${CONFIG_SERVER_SPRING_PROFILES_ACTIVE}
      GIT_REPO: ${CONFIG_SERVER_GIT_REPO}
    volumes:
      - ${CONFIG_SERVER_CONFIG_FOLDER_LOCATION_VOLUME}:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  discovery-server:
    image: ${DISCOVERY_SERVER_IMAGE}
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  customers-service:
    image: ${CUSTOMERS_SERVICE_IMAGE}
    container_name: customers-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy
    profiles:
      - prod

  visits-service:
    image: ${VISITS_SERVICE_IMAGE}
    container_name: visits-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy
    profiles:
      - prod

  vets-service:
    image: ${VETS_SERVICE_IMAGE}
    container_name: vets-service
    environment:
      <<: [ *spring-profiles, *database-connection ]
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy
    profiles:
      - prod

  api-gateway:
    image: ${API_GATEWAY_IMAGE}
    container_name: api-gateway
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 8080:8080
    profiles:
      - prod

  admin-server:
    image: ${ADMIN_SERVER_IMAGE}
    container_name: admin-server
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 9090:9090
    profiles:
      - monitoring

  petclinicdb:
    container_name: database
    image: ${MYSQL_IMAGE}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${PETCLINICDB_MYSQL_ROOT_PASSWORD} # just needed for root user
      MYSQL_USER: ${PETCLINICDB_MYSQL_USER}
      MYSQL_PASSWORD: ${PETCLINICDB_MYSQL_PASSWORD}
      MYSQL_DATABASE: ${PETCLINICDB_MYSQL_DATABASE}
    volumes:
      - ${PETCLINICDB_DATABASE_VOLUME}:/var/lib/mysql
      - ${PETCLINICDB_INIT_SCRIPT_VOLUME}:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      <<: *healthcheck-config
```

Start petclinic without profile
```shell
cd petclinic/spring-petclinic-microservices
docker compose up -d
```
You see that only database service started, as it have no defined profiles   

Start petclinic with profiles
```shell
cd petclinic/spring-petclinic-microservices
docker compose --profile prod --profile monitoring up -d 
```
You see that all services with profiles prod and monitoring started

### 5.) extend compose file

Docker Compose's extends attribute lets you share common configurations among different files, or even different projects entirely.

Extending services is useful if you have several services that reuse a common set of configuration options.
For example in petclinic, we have 3 backend services (customers-service, visits-service, vets-service) with similar settings. 
So, let's move common part to the docker-common.yml / backend-service
```yaml

version: '3.9'

x-spring-profiles: &spring-profiles
  SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE}

x-database-connection: &database-connection
  MYSQL_URL: ${MYSQL_URL}
  MYSQL_USER: ${MYSQL_USER}
  MYSQL_PASSWORD: ${MYSQL_PASSWORD}

services:
  backend-service:
    environment:
      <<: [ *spring-profiles, *database-connection ]
    profiles:
      - prod
```

And use it in the docker-compose.yml with `extends` attribute

```yaml
version: '3.9'

x-depends-on-config-server-and-eureka: &depends-on-config-server-and-eureka
  config-server:
    condition: service_healthy
  discovery-server:
    condition: service_healthy

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

services:

  config-server:
    image: ${CONFIG_SERVER_IMAGE}
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: ${CONFIG_SERVER_SPRING_PROFILES_ACTIVE}
      GIT_REPO: ${CONFIG_SERVER_GIT_REPO}
    volumes:
      - ${CONFIG_SERVER_CONFIG_FOLDER_LOCATION_VOLUME}:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  discovery-server:
    image: ${DISCOVERY_SERVER_IMAGE}
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  customers-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${CUSTOMERS_SERVICE_IMAGE}
    container_name: customers-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  visits-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${VISITS_SERVICE_IMAGE}
    container_name: visits-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  vets-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${VETS_SERVICE_IMAGE}
    container_name: vets-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  api-gateway:
    image: ${API_GATEWAY_IMAGE}
    container_name: api-gateway
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 8080:8080
    profiles:
      - prod

  admin-server:
    image: ${ADMIN_SERVER_IMAGE}
    container_name: admin-server
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 9090:9090
    profiles:
      - monitoring

  petclinicdb:
    container_name: database
    image: ${MYSQL_IMAGE}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${PETCLINICDB_MYSQL_ROOT_PASSWORD} # just needed for root user
      MYSQL_USER: ${PETCLINICDB_MYSQL_USER}
      MYSQL_PASSWORD: ${PETCLINICDB_MYSQL_PASSWORD}
      MYSQL_DATABASE: ${PETCLINICDB_MYSQL_DATABASE}
    volumes:
      - ${PETCLINICDB_DATABASE_VOLUME}:/var/lib/mysql
      - ${PETCLINICDB_INIT_SCRIPT_VOLUME}:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      <<: *healthcheck-config
```

Start petclinic
```shell
cd petclinic/spring-petclinic-microservices
docker compose --profile prod --profile monitoring up -d
```

### 6.) merge compose files

Docker Compose lets you merge and override a set of Compose files together to create a composite Compose file.

By default, Compose reads two files, a docker-compose.yml and an optional docker-compose.override.yml file. 
By convention, the docker-compose.yml contains your base configuration. 
The override file can contain configuration overrides for existing services or entirely new services.

To use multiple override files, or an override file with a different name, 
you can use the -f option to specify the list of files.

Let's create docker-compose.local.yml, that maps mysql port 3306 for the local connection.
NOTE: docker-compose.yml to be used from the chapter 5.
```yaml
version: '3.9'

services:
  petclinicdb:
    ports:
      - 3306:3306

```
 

And start petclinic with this file.
```shell
cd petclinic/spring-petclinic-microservices
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d
```

You'll see that petclinicdb now maps port 3306 and it can be used for the local connection.

### 7.) include compose files

With the include top-level element, you can include a separate Compose file directly in your local Compose file. This solves the relative path problem that extends and merge present.

include makes it easier to modularize complex applications into sub-Compose files. 
This allows application configurations to be made simpler and more explicit.

NOTE: include is available in Docker Compose version 2.20 and later, and Docker Desktop version 4.22 and later.

Let's create docker-include.yml with petclinicdb service defined.

```yaml
version: '3.9'

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

services:

  petclinicdb:
    container_name: database
    image: ${MYSQL_IMAGE}
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${PETCLINICDB_MYSQL_ROOT_PASSWORD} # just needed for root user
      MYSQL_USER: ${PETCLINICDB_MYSQL_USER}
      MYSQL_PASSWORD: ${PETCLINICDB_MYSQL_PASSWORD}
      MYSQL_DATABASE: ${PETCLINICDB_MYSQL_DATABASE}
    volumes:
      - ${PETCLINICDB_DATABASE_VOLUME}:/var/lib/mysql
      - ${PETCLINICDB_INIT_SCRIPT_VOLUME}:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: mysqladmin ping -h localhost -upetclinic -ppetclinic
      <<: *healthcheck-config
```

And update docker-compose.yml, so it will include it.

```yaml
version: '3.9'

x-depends-on-config-server-and-eureka: &depends-on-config-server-and-eureka
  config-server:
    condition: service_healthy
  discovery-server:
    condition: service_healthy

x-healthcheck-config: &healthcheck-config
  interval: 5s
  timeout: 10s
  retries: 3
  start_period: 15s

include:
  - docker-include.yml

services:

  config-server:
    image: ${CONFIG_SERVER_IMAGE}
    restart: always
    container_name: config-server
    environment:
      SPRING_PROFILES_ACTIVE: ${CONFIG_SERVER_SPRING_PROFILES_ACTIVE}
      GIT_REPO: ${CONFIG_SERVER_GIT_REPO}
    volumes:
      - ${CONFIG_SERVER_CONFIG_FOLDER_LOCATION_VOLUME}:/config_folder
    healthcheck:
      test: curl -f http://localhost:8888/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  discovery-server:
    image: ${DISCOVERY_SERVER_IMAGE}
    container_name: discovery-server
    restart: always
    depends_on:
      config-server:
        condition: service_healthy
    healthcheck:
      test: curl -f http://localhost:8761/actuator/health
      <<: *healthcheck-config
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: '512M'
    profiles:
      - prod

  customers-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${CUSTOMERS_SERVICE_IMAGE}
    container_name: customers-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  visits-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${VISITS_SERVICE_IMAGE}
    container_name: visits-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  vets-service:
    extends:
      file: docker-common.yml
      service: backend-service
    image: ${VETS_SERVICE_IMAGE}
    container_name: vets-service
    depends_on:
      <<: *depends-on-config-server-and-eureka
      petclinicdb:
        condition: service_healthy

  api-gateway:
    image: ${API_GATEWAY_IMAGE}
    container_name: api-gateway
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 8080:8080
    profiles:
      - prod

  admin-server:
    image: ${ADMIN_SERVER_IMAGE}
    container_name: admin-server
    depends_on:
      <<: *depends-on-config-server-and-eureka
    ports:
      - 9090:9090
    profiles:
      - monitoring
```

Start petclinic.
```shell
cd petclinic/spring-petclinic-microservices
docker compose --profile prod --profile monitoring up -d
```






