#!/bin/bash

source globals.sh

#######################################
# Removes a peer from the wireguard interface and deletes its 
# entry from the config file.
# Globals:
#   WG_INTERFACE_NAME
# Arguments:
#   Peer's public key
#######################################
function remove_peer() {
    sudo wg set $WG_INTERFACE_NAME peer $1 remove
    remove_peer_from_config $1
}

#######################################
# Removes a peer from the wireguard interface config file.
# Globals:
#   WG_CONFIG_PATH
# Arguments:
#   Peer's public key
#######################################
function remove_peer_from_config() {
    line_number=1
    while read -r line 
    do 
        if [[ "$line" == "[Peer]" ]]
        then
            if [ -n "$line_number_to_delete_from" ] && [ -z "$line_number_to_delete_to" ]
            then
                line_number_to_delete_to=$((line_number - 1))
                break
            fi

            last_peer_line_number=$line_number
        fi

        if [[ "$line" == *"$1"* ]]
        then
            line_number_to_delete_from=$last_peer_line_number
        fi
        ((line_number++))
    done < $WG_CONFIG_PATH

    if [ -z $line_number_to_delete_to ]
    then
        line_number_to_delete_to=$line_number
    fi

    if [ -z "$line_number_to_delete_from" ]; 
    then 
        echo "Failed to find the peer key in the wireguard interface config"
    else 
        sed -i "$line_number_to_delete_from,$line_number_to_delete_to d" $WG_CONFIG_PATH
    fi
}

#######################################
# Displays help message
# Globals:
#   USAGE_MESSAGE
#   PEER_CONFIG_DIR
#######################################
function help() {
    echo "This script removes a peer from the running wireguard interface and deletes it from the interface config."
	echo "$USAGE_MESSAGE"
	echo "Example 1: ./remove-peer.sh mypeer"
    echo "If a peer name is passed, the script will also delete the peer config directory from '$PEER_CONFIG_DIR'."
	echo "Example 2: ./remove-peer.sh -k xzfaIGOdpy57GI8EulgGjJNP7jklvoUBGiQVbVIesQk="
}

USAGE_MESSAGE="Usage: ./remove-peer.sh [PEER_NAME] [-k, --key PEER_PUBLIC_KEY]"
INFO_MESSAGE="Try ./remove-peer.sh -h for more information."

if [ $# -eq 0 ]
then
	echo "$USAGE_MESSAGE"
    echo "$INFO_MESSAGE"
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                help
                exit;;
            -k|--key)
                if [ -z "$2" ]
                then
                    echo "You have to provide a public key as the second argument."
                    echo "$INFO_MESSAGE"
                else
                    remove_peer $2
                fi
                exit;;
            *)
                peer_config_path=$PEER_CONFIG_DIR$1
                public_key=$(cat $peer_config_path/publickey 2>/dev/null)
                if [ -z "$public_key" ]
                then
                    echo "A client with name '$1' does not exist."
                else
                    remove_peer $public_key
                    rm -r $peer_config_path
                fi
                exit;;
        esac
    done
fi
