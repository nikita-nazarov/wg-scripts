#!/bin/bash

WG_INTERFACE_NAME="wg0"
WG_CONFIG_PATH="/etc/wireguard/wg0.conf"
WG_SERVER_PUBLIC_KEY=$(cat /etc/wireguard/publickey)
WG_SERVER_ADDRESS="$(curl -s ifconfig.me):51830"
PEER_CONFIG_DIR="/etc/wireguard/peers/"

# Default peer ip that will be added if no peers are listed in the wireguard interface config
FALLBACK_PEER_IP="10.0.0.2/32"
