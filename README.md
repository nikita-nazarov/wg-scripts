# WireGuard Scripts

This repo contains shell scripts that will allow you to easily add and remove clients **after** the WireGuard server is installed on your machine. 

## Adding a new client
Simply run `add-peer.sh` with a client name provided:
```
./add-peer.sh mypeer
```
After that, the client will be added to a running WireGuard interface. The interface config will be updated, so you won't lose this client after a server restart. Also, a client config file will be generated. After that, you will only need to add this config file to your WireGuard client to start using the server! By default the client config can be found here:
```
/etc/wireguard/peers
`-- mypeer
    |-- mypeer.conf
    |-- privatekey
    `-- publickey
```

## Removing a client
To remove a client simply run:
```
./remove-peer.sh mypeer
```
This will remove the client from the running WireGuard interface and delete its entry from the interface config.

You can also remove a client by its public key:
```
./remove-peer.sh -k <PASTE A PUBLIC KEY HERE>
```

## Configurating
Scripts from this repo depend on [globals.sh](globals.sh), where global constants are defined. Make sure that the contents of this file are aligned with your server parameters! Such as:

* WG_INTERFACE_NAME - the WireGuard interface name, `wg0` by default.
* WG_INTERFACE_NAME - the path to the WireGuard config file, `/etc/wireguard/wg0.conf` by default.
* WG_SERVER_PUBLIC_KEY - the public key of your WireGuard server. By default, it's evaluated with this expression: `cat /etc/wireguard/publickey`.
* WG_SERVER_ADDRESS - the address of the WireGuard server. By default, it's evaluated with this expression `$(curl -s ifconfig.me):51820`.
* PEER_CONFIG_DIR - the path where client config files will be located, `/etc/wireguard/peers/` by default.

## Sending config files to your local machine
To receive the generated client config files, on your local machine run:
```
scp -r <REMOTE MACHINE ADDRESS>:/etc/wireguard/peers/ <PATH ON LOCAL MACHINE>
```
For example:
```
scp -r root@80.200.120.90:/etc/wireguard/peers/ ~/wg/
```