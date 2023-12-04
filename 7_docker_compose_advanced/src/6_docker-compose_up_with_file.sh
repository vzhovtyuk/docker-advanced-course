#!/bin/bash

cd petclinic/spring-petclinic-microservices
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d