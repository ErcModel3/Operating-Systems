#!/bin/bash
# macOS Gateway Setup for Pi Internet Access
# This script enables your Mac to act as a gateway for the Pi
# Pi connects via en8 (10.0.0.100)
# Mac internet via en0 (wifi)

# Enable IP forwarding on macOS
sudo sysctl -w net.inet.ip.forwarding=1
echo "✓ IP forwarding enabled"

# Create pfctl rules to forward traffic
sudo cat > /tmp/pf-pi.conf << 'EOF'
# pfctl rules for Pi gateway
# en0 = wifi (internet)
# en8 = ethernet (Pi connection)

# Skip loopback
set skip on lo0

# Enable nat on wifi interface
nat on en0 from 10.0.0.0/24 to any -> (en0)

# Allow forwarding between en8 and en0
pass in on en8 proto tcp to any
pass in on en8 proto udp to any
pass in on en8 proto icmp to any
pass out on en0 proto tcp from 10.0.0.0/24 to any
pass out on en0 proto udp from 10.0.0.0/24 to any
pass out on en0 proto icmp from 10.0.0.0/24 to any

# Allow return traffic
pass in on en0 proto tcp to 10.0.0.0/24
pass in on en0 proto udp to 10.0.0.0/24
pass in on en0 proto icmp to 10.0.0.0/24
EOF

# Load the rules
sudo pfctl -f /tmp/pf-pi.conf
echo "✓ pfctl rules loaded"

# Enable pfctl if not already enabled
sudo pfctl -e
echo "✓ pfctl enabled"

echo ""
echo "Gateway setup complete!"
echo ""
echo "Now on the Pi, run:"
echo "  sudo sysctl -w net.ipv4.ip_forward=1"
echo "  ping 8.8.8.8"
echo "  sudo apt update"
