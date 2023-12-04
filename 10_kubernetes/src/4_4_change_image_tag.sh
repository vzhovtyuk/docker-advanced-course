#!/bin/bash

kubectl set image deployment/nginx-deployment nginx-container=nginx:1.25.3
kubectl rollout history deployment/nginx-deployment