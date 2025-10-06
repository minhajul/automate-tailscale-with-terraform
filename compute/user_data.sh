#!/bin/bash

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

# Start Tailscale and advertise as exit node
tailscale up --authkey=${tailscale_auth_key} --advertise-exit-node --accept-routes

echo "Tailscale exit node setup complete"