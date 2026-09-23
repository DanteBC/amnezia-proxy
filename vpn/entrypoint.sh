#!/bin/sh
set -eu

config=${AMNEZIAWG_CONFIG:-/etc/amnezia/awg0.conf}
interface=awg0

endpoint=$(awk -F ' *= *' '$1 == "Endpoint" { print $2; exit }' "$config")
endpoint_host=${endpoint%:*}
endpoint_port=${endpoint##*:}
endpoint_ip=$(getent ahostsv4 "$endpoint_host" | awk 'NR == 1 { print $1 }')

[ -n "$endpoint_ip" ] || {
  printf '%s\n' "Could not resolve AmneziaWG endpoint: $endpoint_host" >&2
  exit 1
}

sed "s/^Endpoint = .*/Endpoint = $endpoint_ip:$endpoint_port/; /^\[Interface\]/a Table = off" "$config" > /tmp/awg0.conf

export WG_QUICK_USERSPACE_IMPLEMENTATION=/usr/local/bin/amneziawg-go
gateway_route=$(ip route show default | sed 's/^default //' | head -n 1)
awg-quick up /tmp/awg0.conf

ip route replace "$endpoint_ip/32" $gateway_route
ip route replace default dev "$interface"
ip -6 route replace default dev "$interface" 2>/dev/null || true

iptables -I OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I OUTPUT -d "$endpoint_ip" -p udp --dport "$endpoint_port" -j ACCEPT
iptables -A OUTPUT -o "$interface" -j ACCEPT
iptables -A OUTPUT -j REJECT

trap 'awg-quick down /tmp/awg0.conf' INT TERM EXIT
while :; do sleep 3600; done
