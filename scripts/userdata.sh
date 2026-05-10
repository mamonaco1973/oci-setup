#!/bin/bash

# OCI fires cloud-init before DNS resolves — wait explicitly for resolution
until nslookup archive.ubuntu.com > /dev/null 2>&1; do
  sleep 5
done

# archive.ubuntu.com has been under sustained DDoS since May 2026 — use regional mirror
sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's|http://security.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources

apt-get update -y
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2