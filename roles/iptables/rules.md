# Iptables Firewall Rules Documentation

## Overview

This document explains the iptables rules implemented across three network zones for the Raspberry Pi firewall. Each template corresponds to a specific network class and implements appropriate security controls.

## Network Architecture

| Zone | Interface | Network | Gateway IP | Security Level |
|------|-----------|---------|------------|----------------|
| WAN (Internet) | eth0 | 10.0.0.0/8 | 10.0.0.5/8 | External |
| LAN (Trusted) | eth1 | 172.16.0.0/16 | 172.16.0.1/16 | High Trust |
| Guest (IoT) | eth2 | 192.168.0.0/24 | 192.168.0.1/24 | Low Trust |

## Default Policy

All templates implement a **default deny** policy:
- `INPUT DROP` - Reject all incoming traffic unless explicitly allowed
- `FORWARD DROP` - Block all forwarding unless explicitly permitted
- `OUTPUT ACCEPT` - Allow all outbound traffic from firewall

## class-a.j2 (WAN Interface - eth0)

### Purpose
Manages internet-facing traffic and routing between internal zones and the public internet.

### Filter Table Rules

#### INPUT Chain
- **Loopback**: Allows all loopback traffic (`lo`)
- **Stateful**: Permits established and related connections
- **SSH**: Accepts SSH connections on port 22 (management access)
- **ICMP**: Allows ping requests
- **HTTP/HTTPS**: Permits web traffic (ports 80, 443)
- **DNS**: Accepts DNS queries (UDP/TCP port 53)
- **Logging**: Logs all dropped packets with prefix "INPUT-DROP:"

#### FORWARD Chain
- **Stateful**: Allows established/related connections
- **LAN to WAN**: Permits eth1 → eth0 forwarding
- **Guest to WAN**: Permits eth2 → eth0 forwarding
- **Zone Isolation**: Blocks eth1 ↔ eth2 (LAN and Guest cannot communicate)
- **Remote Access Block**: Drops SSH (22), Telnet (23), RDP (3389)
- **TCP Flag Validation**: Drops NULL packets and XMAS attacks
- **Logging**: Logs dropped forwards with prefix "FORWARD-DROP:"

### NAT Table Rules

#### POSTROUTING Chain
- **Primary Masquerade**: Masquerades all outbound traffic on eth0
- **LAN Masquerade**: Specifically handles 172.16.0.0/16 source NAT
- **Guest Masquerade**: Handles 192.168.0.0/24 source NAT

### Mangle Table Rules

#### PREROUTING Chain
- **Invalid State Drop**: Drops packets with invalid connection tracking state
- **TCP SYN Validation**: Blocks non-SYN packets trying to establish new connections
- **TCP Flag Attacks**: Drops NULL, XMAS, SYN+FIN, SYN+RST combinations
- **Fragment Protection**: Drops fragmented packets to prevent attacks

## class-b.j2 (LAN Interface - eth1)

### Purpose
Manages trusted internal network with higher privileges and access to internal services.

### Filter Table Rules

#### INPUT Chain
- **Loopback**: Allows all loopback traffic
- **Stateful**: Permits established/related connections
- **SSH**: Accepts SSH from LAN (trusted management)
- **ICMP**: Allows ping from LAN
- **DHCP**: Permits DHCP client/server (ports 67-68)
- **DNS**: Accepts DNS queries
- **HTTP/HTTPS**: Allows web traffic
- **Development Ports**: Opens ports 3000 and 8080 for development services
- **LAN Access**: Accepts all traffic from 172.16.0.0/16 subnet
- **Logging**: Logs drops with prefix "INPUT-DROP-LAN:"

#### FORWARD Chain
- **Stateful**: Allows established/related connections
- **LAN to Internet**: Permits 172.16.0.0/16 → eth0 forwarding
- **Zone Isolation**: Blocks eth1 → eth2 (LAN cannot reach Guest)
- **Return Traffic**: Allows WAN → LAN for established connections only
- **Dangerous Ports**: Blocks SMTP (25), RPC (135), NetBIOS (139), SMB (445)
- **Logging**: Logs drops with prefix "FORWARD-DROP-LAN:"

### NAT Table Rules

#### POSTROUTING Chain
- **LAN Masquerade**: NAT for 172.16.0.0/16 traffic going to internet

### Mangle Table Rules

#### PREROUTING Chain
- **Invalid State Drop**: Drops invalid connection states from LAN
- **TCP SYN Validation**: Ensures proper TCP connection establishment
- **Source Validation**: Accepts traffic from valid LAN subnet

## class-c.j2 (Guest Interface - eth2)

### Purpose
Highly restrictive zone for untrusted devices (IoT, guest devices) with minimal access.

### Filter Table Rules

#### INPUT Chain
- **Loopback**: Allows loopback traffic
- **Stateful**: Permits established/related connections
- **ICMP**: Allows ping only
- **DHCP**: Permits DHCP (ports 67-68)
- **DNS**: Accepts DNS queries
- **HTTP/HTTPS**: Allows web traffic only
- **SSH Block**: Explicitly denies SSH to firewall from Guest zone
- **Rate Limiting**: Limits input to 10 packets/min from Guest network
- **Logging**: Logs drops with prefix "INPUT-DROP-GUEST:"

#### FORWARD Chain
- **Stateful**: Allows established/related connections
- **Guest to Internet Only**: Permits 192.168.0.0/24 → eth0 forwarding
- **Zone Isolation**: Blocks eth2 → eth1 (Guest cannot reach LAN)
- **LAN Protection**: Explicitly blocks destination 172.16.0.0/16
- **Return Traffic**: Allows WAN → Guest for established connections only
- **Remote Access Block**: Drops SSH (22), Telnet (23), RDP (3389)
- **Windows Sharing Block**: Drops RPC (135), NetBIOS (139), SMB (445)
- **Database Protection**: Blocks MSSQL (1433), MySQL (3306), PostgreSQL (5432)
- **Rate Limiting**: Limits forwarding to 100 packets/sec with burst of 200
- **Logging**: Logs drops with prefix "FORWARD-DROP-GUEST:"

### NAT Table Rules

#### POSTROUTING Chain
- **Guest Masquerade**: NAT for 192.168.0.0/24 traffic going to internet

### Mangle Table Rules

#### PREROUTING Chain
- **Invalid State Drop**: Drops invalid connection states
- **TCP SYN Validation**: Ensures proper connection establishment
- **TCP Flag Attacks**: Comprehensive protection against NULL, XMAS, SYN+FIN, SYN+RST
- **Source Validation**: Accepts traffic from valid Guest subnet
- **Spoofing Prevention**: Blocks spoofed packets from Class A (10.0.0.0/8) and Class B (172.16.0.0/12) ranges

## Security Features

### Connection Tracking
All templates use stateful packet inspection to track connection states:
- `ESTABLISHED`: Part of existing connection
- `RELATED`: Related to established connection (e.g., FTP data channel)
- `NEW`: Attempting to establish new connection
- `INVALID`: Doesn't match any known connection

### Logging Strategy
Each zone has distinct logging prefixes for troubleshooting:
- **WAN**: `INPUT-DROP:`, `FORWARD-DROP:`
- **LAN**: `INPUT-DROP-LAN:`, `FORWARD-DROP-LAN:`
- **Guest**: `INPUT-DROP-GUEST:`, `FORWARD-DROP-GUEST:`

View logs with: `journalctl -k | grep iptables` or check `/var/log/kern.log`

### Rate Limiting
Protects against DoS attacks:
- **Guest Input**: 10 packets/minute to firewall
- **Guest Forward**: 100 packets/second with burst capacity of 200

### Network Address Translation (NAT)
All internal zones use MASQUERADE for outbound internet access:
- Allows multiple internal devices to share single public IP
- Automatically adapts to dynamic IP addresses on WAN interface
- Maintains connection tracking for return traffic

## Zone Communication Matrix

| Source → Destination | WAN (eth0) | LAN (eth1) | Guest (eth2) |
|---------------------|------------|------------|--------------|
| WAN (eth0) | - | Established only | Established only |
| LAN (eth1) | ✓ Allowed | - | ✗ Blocked |
| Guest (eth2) | ✓ Allowed | ✗ Blocked | - |

## Common Blocked Ports

| Port | Service | Reason |
|------|---------|--------|
| 22 | SSH | Prevent unauthorized remote access |
| 23 | Telnet | Insecure protocol |
| 25 | SMTP | Prevent spam relay |
| 135 | MS-RPC | Windows vulnerability vector |
| 139 | NetBIOS | Windows file sharing exposure |
| 445 | SMB | Ransomware/WannaCry vector |
| 1433 | MSSQL | Database exposure |
| 3306 | MySQL | Database exposure |
| 3389 | RDP | Brute force target |
| 5432 | PostgreSQL | Database exposure |

## Attack Prevention

### TCP Flag Validation
Protects against reconnaissance and DoS attacks:
- **NULL Scan**: All flags off
- **XMAS Scan**: All flags on
- **Invalid Combinations**: SYN+FIN, SYN+RST

### Fragment Protection
Blocks fragmented packets to prevent:
- Fragment overlap attacks
- Tiny fragment attacks
- Buffer overflow attempts

### Spoofing Prevention (Guest Zone)
Drops packets with source IPs from private ranges that shouldn't appear on Guest network:
- Prevents IP spoofing attacks
- Stops lateral movement attempts
- Enforces proper network segmentation

## Deployment

These templates are deployed via Ansible using the iptables role:

```bash
ansible-playbook -i inventory iptables.yml
```

Rules are made persistent using `iptables-persistent` package and automatically restored on reboot.

## Testing Commands

Verify rules are loaded:
```bash
iptables -L -v -n
iptables -t nat -L -v -n
iptables -t mangle -L -v -n
```

Test connectivity:
```bash
# From LAN device
ping 8.8.8.8                    # Should work
ping 192.168.0.1                # Should fail (blocked)

# From Guest device
ping 8.8.8.8                    # Should work
ping 172.16.0.1                 # Should fail (blocked)
ssh user@172.16.0.10            # Should fail (blocked)
```

Check packet counters:
```bash
watch -n 1 'iptables -L -v -n | head -20'
```

## Maintenance

### View Logs
```bash
journalctl -k | grep "INPUT-DROP"
journalctl -k | grep "FORWARD-DROP"
tail -f /var/log/kern.log | grep iptables
```

### Backup Current Rules
```bash
iptables-save > /etc/iptables/rules.backup
```

### Restore Rules Manually
```bash
iptables-restore < /etc/iptables/class-a
iptables-restore < /etc/iptables/class-b
iptables-restore < /etc/iptables/class-c
```

## Troubleshooting

### No Internet Access from LAN/Guest
1. Check IP forwarding: `sysctl net.ipv4.ip_forward`
2. Verify NAT rules: `iptables -t nat -L -v -n`
3. Check WAN interface is up: `ip addr show eth0`

### Cannot SSH to Firewall
1. Verify you're connecting from correct zone (LAN, not Guest)
2. Check INPUT rules: `iptables -L INPUT -v -n`
3. Confirm SSH service running: `systemctl status ssh`

### High Packet Drop Rate
1. Review logs to identify source
2. Check for legitimate traffic being blocked
3. Adjust rate limits if necessary

## Security Considerations

- **SSH access** should be further restricted by IP address in production
- **Logging** generates significant disk I/O; monitor disk usage
- **Rate limits** may need tuning based on actual traffic patterns
- **Port forwarding** rules should be added carefully with specific source restrictions
- Regular **log review** is essential for detecting attack attempts
- Consider implementing **fail2ban** for additional brute force protection
