#!/bin/bash

kubectl get secret --namespace helm phpmyadmin-mariadb -o jsonpath="{.data.mariadb-root-password}" | base64 -d