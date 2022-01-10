#!/bin/bash

echo "Wait 5 seconds until we start docker..."
sleep 5

# Log in to container registry
/opt/docker-login.sh

# Start docker and ensure the web_gateway network exists
service docker start
echo "Wait 5 seconds until docker is ready..."
sleep 5
docker network create -d bridge web_net

# Open up ports in iptables
/sbin/iptables-restore -n /01_data/iptables.conf

