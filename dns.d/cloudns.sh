#!/bin/bash
set -eo pipefail

get_wildcard_address() {
   local URL='https://api.cloudns.net/dns/records.json'
   curl "$URL?$CLOUDNS_AUTH&domain-name=$1" \
      | teepee \
         -T '[%
            for my $r (HV "") {
               next unless ($r->{type} eq "A") && ($r->{host} eq "*");
               print $r->{record}, "\n";
            }
         %]'
}

set_wildcard_address() {
   local URL='https://api.cloudns.net/dns/add-record.json'
   local DOMAIN="domain-name=$1"
   local ADDRESS="record=$2"
   local STUFF='record-type=A&host=*&ttl=60&status=1'
   local OUT=$(
      curl -X POST "$URL?$CLOUDNS_AUTH&$DOMAIN&$ADDRESS&$STUFF" \
         | teepee -v status
   )
   [ "$OUT" == "Success" ]
}

command="$1"
shift
case "$command" in
   (get-wildcard-address|get_wildcard_address)
      get_wildcard_address "$@"
      ;;
   (set-wildcard-address|set_wildcard_address)
      set_wildcard_address "$@"
      ;;
esac
