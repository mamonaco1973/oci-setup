#!/bin/bash

# OCI fires cloud-init before DNS resolves — wait explicitly for resolution
echo "NOTE: Waiting for DNS resolution..."
until nslookup archive.ubuntu.com > /dev/null 2>&1; do
  echo "NOTE: DNS not ready, retrying in 5 seconds..."
  sleep 5
done
echo "NOTE: DNS resolved."

# archive.ubuntu.com has been under sustained DDoS since May 2026 — use regional mirror
echo "NOTE: Switching apt sources to regional mirror..."
sed -i 's|http://archive.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's|http://security.ubuntu.com|http://us.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources

echo "NOTE: Running apt-get update..."
apt-get update -y

echo "NOTE: Installing apache2..."
apt-get install -y apache2

echo "NOTE: Enabling and starting apache2..."
systemctl enable apache2
systemctl start apache2

# OCI Ubuntu images block all ports except 22 via iptables by default —
# the Security List alone is not enough
echo "NOTE: Opening port 80 in host firewall..."
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

echo "NOTE: Done."