#!/bin/bash

set -eo pipefail

base_rules_ipv4() {
   cat <<END
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth0    -p icmp --icmp-type echo-request -m limit --limit 2/second -j ACCEPT
-A INPUT -i eth0    -p tcp -m tcp --dport    22 -j ACCEPT 
-A INPUT -i eth0    -p tcp -m tcp --dport    80 -j ACCEPT 
-A INPUT -i eth0    -p tcp -m tcp --dport   443 -j ACCEPT 
-A INPUT -i docker0 -p tcp -m tcp --dport    80 -j ACCEPT 
-A INPUT -i docker0 -p tcp -m tcp --dport   443 -j ACCEPT 
-A OUTPUT -s 127.0.0.1 -j ACCEPT
END
}

base_rules_ipv6() {
   cat <<END
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth0    -p icmpv6 -m limit --limit 2/second -j ACCEPT
-A INPUT -i eth0    -p tcp    -m tcp   --dport       22 -j ACCEPT 
-A INPUT -i eth0    -p tcp    -m tcp   --dport       80 -j ACCEPT 
-A INPUT -i eth0    -p tcp    -m tcp   --dport      443 -j ACCEPT 
-A INPUT -i docker0 -p tcp    -m tcp   --dport       80 -j ACCEPT 
-A INPUT -i docker0 -p tcp    -m tcp   --dport      443 -j ACCEPT 
-A OUTPUT -s ::1 -j ACCEPT
END
}

ipv4_ips() {
   local IP
   for IP in $(hostname -I) ; do printf '%s\n' "$IP" ; done | grep -v ':'
}

ipv6_ips() {
   local IP
   for IP in $(hostname -I) ; do printf '%s\n' "$IP" ; done | grep ':'
}

ensure_rules() {
   local N_IP=$("$IPS" | wc -w)
   [ "$N_IP" -gt 0 ] || return 0

   local RELOAD=''

   if [ -n "$REGEN_RULES" -o ! -e "$RULES" ] ; then
      {
         "$BASE_RULES"
         "$IPS" | sed -e 's/^\(.*\)/-A OUTPUT -s \1 -j ACCEPT/'
         printf 'COMMIT\n'
      } >"$RULES.tmp"
      mv "$RULES.tmp" "$RULES"
      RELOAD=1
   fi

   if [ ! -e "$IFUP" ] ; then
      cat >"$IFUP.tmp" <<END
#!/bin/sh
"$IPTABLES-restore" <"$RULES"
END
      chmod +x "$IFUP.tmp"
      mv "$IFUP.tmp" "$IFUP"
   fi

   [ -z "$RELOAD" ] && return 0
   sh "$IFUP"
}

IPV=ipv4 \
   REGEN_RULES="$1"                     \
   RULES='/etc/network/iptables.rules'  \
   IPTABLES=iptables                    \
   BASE_RULES=base_rules_ipv4           \
   IPS=ipv4_ips                         \
   IFUP='/etc/network/if-up.d/iptables' \
      ensure_rules

IPV=ipv6 \
   REGEN_RULES="$1"                      \
   RULES='/etc/network/ip6tables.rules'  \
   IPTABLES=ip6tables                    \
   BASE_RULES=base_rules_ipv6            \
   IPS=ipv6_ips                          \
   IFUP='/etc/network/if-up.d/ip6tables' \
      ensure_rules

exit 0
