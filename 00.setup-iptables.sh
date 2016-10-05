#!/bin/bash

set -eo pipefail

RULES='/etc/network/iptables.rules'
if [ ! -e "$RULES" ] ; then
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
fi

IFUP='/etc/network/if-up.d/iptables'
cat >"$IFUP" <<END
#!/bin/sh
iptables-restore <"$RULES"
END
chmod +x "$IFUP"
sh "$IFUP"
