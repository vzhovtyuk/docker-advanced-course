#!/bin/bash

kubectl scale deployment/nginx-deployment --replicas=6
kubectl get pods