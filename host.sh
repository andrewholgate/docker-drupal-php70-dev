#!/bin/bash

# Project variables.
URL=php70dev.example.com
CONTAINER_NAME=dockerdrupalphp70dev_drupalphp70devweb_1

# DO NOT EDIT BELOW

# Remove IP address entry for the host name.
sudo sed -i_bak -e "/$URL/d" /etc/hosts

# Add IP address to hosts file.
sudo bash -c "echo $(sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' \
$CONTAINER_NAME) $URL >> /etc/hosts"

echo
echo Login to container: sudo docker exec -it $CONTAINER_NAME su - ubuntu
echo Opening site: xdg-open http://$URL


