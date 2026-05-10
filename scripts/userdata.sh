#!/bin/bash

# OCI fires cloud-init before DNS resolves — wait until apt repos are reachable
until apt-get update -y > /dev/null 2>&1; do
  sleep 5
done

apt-get install -y apache2
systemctl enable apache2
systemctl start apache2