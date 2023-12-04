#!/bin/bash
echo "testpassword" | docker secret create mysql_external_secret -

docker stack deploy --compose-file=docker-compose-secret.yaml mysql_secret_test

 docker exec -it b880f0cd80fd sh

 mysql -uroot -p
