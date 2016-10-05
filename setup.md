# Upgrade

`upgrade-debian.sh`

    apt-get update
    apt-get upgrade

Execute:

    sudo bash upgrade-debian.sh


# Iptables

`/etc/network/iptables.rules`

    *filter
    :INPUT DROP [470:40604]
    :FORWARD DROP [96:6036]
    :OUTPUT DROP [58:4872]
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
    -A INPUT -i lo -j ACCEPT 
    -A INPUT -i eth0 -p icmp --icmp-type echo-request -m limit --limit 2/second -j ACCEPT
    -A INPUT -i eth0 -p tcp -m tcp --dport    22 -j ACCEPT 
    -A INPUT -i eth0 -p tcp -m tcp --dport    80 -j ACCEPT 
    -A INPUT -i eth0 -p tcp -m tcp --dport   443 -j ACCEPT 
    -A OUTPUT -s 127.0.0.1 -j ACCEPT 
    -A OUTPUT -s [% host_ip %] -j ACCEPT COMMIT

`/etc/network/if-up.d/iptables` (ensure execution bit)

    #!/bin/sh
    iptables-restore < /etc/network/iptables.rules

Script `setup-iptables.sh`:

    #!/bin/bash

    set -eo pipefail

    RULES='/etc/network/iptables.rules'
    {
        cat <<END
    *filter
    :INPUT DROP [470:40604]
    :FORWARD DROP [96:6036]
    :OUTPUT DROP [58:4872]
    -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
    -A INPUT -i lo -j ACCEPT 
    -A INPUT -i eth0 -p icmp --icmp-type echo-request -m limit --limit 2/second -j ACCEPT
    -A INPUT -i eth0 -p tcp -m tcp --dport    22 -j ACCEPT 
    -A INPUT -i eth0 -p tcp -m tcp --dport    80 -j ACCEPT 
    -A INPUT -i eth0 -p tcp -m tcp --dport   443 -j ACCEPT 
    -A OUTPUT -s 127.0.0.1 -j ACCEPT
    END
        
        for ip in $(hostname -I) ; do
            echo "-A OUTPUT -s $ip -j ACCEPT"
        done

        echo COMMIT
    }>"$RULES"

    IFUP='/etc/network/if-up.d/iptables'
    cat >"$IFUP" <<END
    #!/bin/sh
    iptables-restore <"$RULES"
    END
    chmod +x "$IFUP"
    sh "$IFUP"



Execute:

    sudo 
    
    sudo /etc/network/if-up.d/iptables

the first time.

# Dokku installation

## Low-memory VPS (< 1GB)

`create-swap.sh`
    
    #!/bin/bash
    IMG='/var/swap.img'
    [ -e "$IMG" ] && exit 0

    touch "$IMG"
    chmod 600 "$IMG"
    dd if=/dev/zero of="$IMG" bs=1024k count=1000
    mkswap "$IMG"
    swapon "$IMG"

Execute:

    sudo ./create-swap.sh

## Download and Install

    


    sudo apt-get update

    wget https://raw.githubusercontent.com/dokku/dokku/v0.7.2/bootstrap.sh
    sudo DOKKU_TAG=v0.7.2 bash bootstrap.sh
