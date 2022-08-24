#!/bin/bash

WG_INTERFACE_NAME="wg0"
WG_CONFIG_PATH="/etc/wireguard/wg0.conf"
WG_SERVER_PUBLIC_KEY=$(cat /etc/wireguard/publickey)
WG_SERVER_ADDRESS="$(curl -s ifconfig.me):51820"
PEER_CONFIG_DIR="/etc/wireguard/peers/"
