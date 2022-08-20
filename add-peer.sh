#!/bin/bash

source globals.sh

#######################################
# Adds a peer to a running wireguard interface, updates the interface config file 
# and creates a peer config file.
# Globals:
#   WG_INTERFACE_NAME
#   WG_CONFIG_PATH
#   PEER_CONFIG_DIR
#   FALLBACK_PEER_IP
# Arguments:
#   Peer's name
#######################################
function add_peer() {
    peer_name=$1
    peer_config_path="$PEER_CONFIG_DIR/$peer_name"

    mkdir -p $peer_config_path
    wg genkey | tee $peer_config_path/privatekey | wg pubkey > $peer_config_path/publickey
    
    highest_ip=$(get_highest_peer_ip_from_config)
    if [ -z "$highest_ip" ] 
    then 
        peer_ip=$FALLBACK_PEER_IP 
    else 
        peer_ip=$(increment_ip $highest_ip) 
    fi

    if [ -z "$peer_ip" ]; 
    then 
        echo "Failed to calculate the new ip address";
        exit 1;
    fi
    
    peer_public_key=$(cat $peer_config_path/publickey)
    peer_private_key=$(cat $peer_config_path/privatekey)

    sudo wg set $WG_INTERFACE_NAME peer $peer_public_key allowed-ips $peer_ip
    fetch_peer_config $peer_ip $peer_private_key > $peer_config_path/$peer_name.conf
    fetch_peer_declaration_for_server_config $peer_ip $peer_public_key >> $WG_CONFIG_PATH
}

#######################################
# Gets the highest defined client ip from the wireguard interface config file.
# Globals:
#   WG_CONFIG_PATH
# Arguments:
#   None
#######################################
function get_highest_peer_ip_from_config() {
    awk -F '=' '$1~/AllowedIPs/ { print $2 }' $WG_CONFIG_PATH | sort | tail -1
}

#######################################
# Increments the ip address
# Arguments:
#   IP address as string
#######################################
function increment_ip() {
    IFS='/' read -ra address <<< "$1"
    if [ ${#address[@]} -eq 2 ]
    then
        ip=${address[0]}
        ip_hex=$(printf '%.2X%.2X%.2X%.2X\n' `echo $ip | sed -e 's/\./ /g'`)
        next_ip_hex=$(printf %.8X `echo $(( 0x$ip_hex + 1 ))`)
        next_ip=$(printf '%d.%d.%d.%d\n' `echo $next_ip_hex | sed -r 's/(..)/0x\1 /g'`)

        echo $next_ip/${address[1]}
    fi
}

#######################################
# Fetches the client config.
# Globals:
#   WG_SERVER_ADDRESS  
#   WG_SERVER_PUBLIC_KEY
# Arguments:
#   1 - Peer's ip
#   2 - Peer's private key
#######################################
function fetch_peer_config() {
    cat << EOF
[Interface]
Address = $1
PrivateKey = $2
DNS = 8.8.8.8

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $WG_SERVER_ADDRESS
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 20
EOF
}

#######################################
# Fetches the client declaration for the wireguard interface config.
# Arguments:
#   1 - Peer's ip
#   2 - Peer's public key
#######################################
function fetch_peer_declaration_for_server_config() {
    cat << EOF
[Peer]
AllowedIPs = $1
PublicKey = $2

EOF
}

if [ $# -eq 0 ]
then
	echo "You must pass a client name as the first argument"
else    
    add_peer $1
fi