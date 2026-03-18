#!/bin/bash

read -p "Salt Master Master : " salt_master
read -p "Minion ID: " minion_id

curl -L https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.sh | sh -s -- -A "${salt_master}" -i "${minion_id}" onedir
