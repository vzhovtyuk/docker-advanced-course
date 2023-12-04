#!/bin/bash

docker buildx create --name custom_builder --driver=docker-container --bootstrap --use
docker buildx ls