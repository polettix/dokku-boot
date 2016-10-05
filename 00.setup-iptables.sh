#!/bin/bash

set -eo pipefail
REGEN_RULES="$1"
RELOAD=''

RULES='/etc/network/iptables.rules'
if [ -n "$REGEN_RULES" -o ! -e "$RULES" ] ; then
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

         if [ -n "$REGEN_RULES" ] ; then
            eip="$(echo "$ip" | sed -e 's/\./[.]/g')"
            if ! iptables -S OUTPUT | grep " $eip/" >/dev/null 2>&1 ; then
               # rule is not present, add it
               iptables -A OUTPUT -s "$ip" -j ACCEPT
            fi
         fi
      done

      echo COMMIT
   }>"$RULES.tmp"
   mv "$RULES.tmp" "$RULES"

   [ -z "$REGEN_RULES" ] && RELOAD=1
fi

IFUP='/etc/network/if-up.d/iptables'
if [ ! -e "$IFUP" ] ; then
   cat >"$IFUP.tmp" <<END
#!/bin/sh
iptables-restore <"$RULES"
END
   chmod +x "$IFUP.tmp"
   mv "$IFUP.tmp" "$IFUP"
fi

[ -n "$RELOAD" ] && sh "$IFUP"
