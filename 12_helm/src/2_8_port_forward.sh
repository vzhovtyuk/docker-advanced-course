#!/bin/bash

kubectl port-forward -n helm svc/phpmyadmin 8086:80