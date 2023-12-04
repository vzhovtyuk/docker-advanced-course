#!/bin/bash

kubectl config current-context
kubectl get pods -A # from all namespaces
minikube dashboard