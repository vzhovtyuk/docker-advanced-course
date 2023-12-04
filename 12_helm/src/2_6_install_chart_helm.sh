#!/bin/bash

helm install phpmyadmin bitnami/phpmyadmin --version 13.1.2 -n helm -f phpmyadmin/values.yml