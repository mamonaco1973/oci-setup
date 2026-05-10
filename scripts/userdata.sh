#!/bin/bash

# OCI fires cloud-init before DNS resolves — wait explicitly for resolution
echo "NOTE: Waiting for DNS resolution..."
until nslookup archive.ubuntu.com > /dev/null 2>&1; do
  echo "NOTE: DNS not ready, retrying in 5 seconds..."
  sleep 5
done
echo "NOTE: DNS resolved."

# OCI images ship with a region-specific mirror (*.clouds.archive.ubuntu.com) that
# fails on IPv6. archive.ubuntu.com is also DDoS'd (May 2026). Overwrite the entire
# sources file to force all traffic through us.archive.ubuntu.com.
echo "NOTE: Replacing apt sources with us.archive.ubuntu.com..."
cat > /etc/apt/sources.list.d/ubuntu.sources << 'EOF'
Types: deb
URIs: http://us.archive.ubuntu.com/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://us.archive.ubuntu.com/ubuntu
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

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