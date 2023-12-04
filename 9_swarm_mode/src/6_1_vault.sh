#!/bin/bash

docker run -itd --cap-add=IPC_LOCK -e 'VAULT_DEV_ROOT_TOKEN_ID=myroot' -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' -p 8200:8200 --name vault vault
export VAULT_ADDR='http://127.0.0.1:8200'

vault login myroot
vault kv put secret/test password=mysecretpasswordtest
