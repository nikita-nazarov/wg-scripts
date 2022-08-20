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
    # sudo wg set $WG_INTERFACE_NAME peer $1 remove
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
            echo "$1"
            line_number_to_delete_from=$last_peer_line_number
        fi
        ((line_number++))
    done < $WG_CONFIG_PATH

    if [ -z $line_number_to_delete_to ]
    then
        line_number_to_delete_to=$((line_number - 1))
    fi

    if [ -z "$line_number_to_delete_from" ]; 
    then 
        echo "Failed to find the peer key in the wireguard interface config"
    else 
        sed "$line_number_to_delete_from,$line_number_to_delete_to d" $WG_CONFIG_PATH
    fi
}

function help() {
    echo "This script removes a peer from a running wireguard interface as well as deletes it from the interface config."
}

if [ $# -eq 0 ]
then
	echo "Usage: ./remove-peer.sh [PEER_NAME] [-k, --key PEER_PUBLIC_KEY]"
    echo "Try ./remove-peer.sh -h for more information."
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h,--help)
                help
                exit;;
            -k|--key)
                if [ -z "$2" ]
                then
                    echo "You have to provide a public key as the second argument."
                    echo "Try ./remove-peer.sh -h for more information."
                else
                    remove_peer $2
                fi
                exit;;
            *)
                public_key=$(cat $PEER_CONFIG_DIR$1/publickey 2>/dev/null)
                if [ -z "$public_key" ]
                then
                    echo "A client with name '$1' does not exist."
                else
                    remove_peer $public_key
                fi
                exit;;
        esac
    done
fi
