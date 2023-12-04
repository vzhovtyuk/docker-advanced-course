#!/bin/bash

kubectl rollout undo deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment
kubectl describe deployment nginx-deployment