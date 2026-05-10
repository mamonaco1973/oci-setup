#!/bin/bash

# OCI fires cloud-init before internet routing is established. nslookup
# succeeds early via local resolver — test actual IPv4 HTTP connectivity.
echo "NOTE: Waiting for network connectivity..."
until curl -4 -sf --max-time 5 http://us.archive.ubuntu.com/ubuntu/ > /dev/null 2>&1; do
  echo "NOTE: Network not ready, retrying in 5 seconds..."
  sleep 5
done
echo "NOTE: Network ready."

# OCI images ship with a region-specific mirror (*.clouds.archive.ubuntu.com)
# that resolves IPv6-only. Overwrite to force all traffic through
# us.archive.ubuntu.com via IPv4.
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

# Force IPv4 — OCI instances have no IPv6 routing; apt prefers AAAA records
echo "NOTE: Running apt-get update..."
apt-get -o Acquire::ForceIPv4=true update -y

echo "NOTE: Installing apache2..."
apt-get -o Acquire::ForceIPv4=true install -y apache2

echo "NOTE: Enabling and starting apache2..."
systemctl enable apache2
systemctl start apache2

# OCI Ubuntu images block all ports except 22 via iptables by default —
# the Security List alone is not enough
echo "NOTE: Opening port 80 in host firewall..."
iptables -I INPUT -p tcp --dport 80 -j ACCEPT

echo "NOTE: Done."
