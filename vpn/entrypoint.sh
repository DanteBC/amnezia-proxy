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
awg-quick up /tmp/awg0.conf

# Запоминаем оригинальный маршрут по умолчанию
orig_default=$(ip route show default | head -n 1)
orig_gateway=$(echo "$orig_default" | awk '{print $3}')
orig_iface=$(echo "$orig_default" | awk '{print $5}')

# Маршрут до endpoint через оригинальный шлюз (чтобы VPN не зациклился)
ip route replace "$endpoint_ip/32" via "$orig_gateway" dev "$orig_iface"

# Заменяем default на awg0
ip route replace default dev "$interface"

# Возвращаем маршруты для приватных сетей через оригинальный шлюз
ip route replace 10.0.0.0/8 via "$orig_gateway" dev "$orig_iface" 2>/dev/null || true
ip route replace 172.16.0.0/12 via "$orig_gateway" dev "$orig_iface" 2>/dev/null || true
ip route replace 192.168.0.0/16 via "$orig_gateway" dev "$orig_iface" 2>/dev/null || true

# IPv6 (опционально)
ip -6 route replace default dev "$interface" 2>/dev/null || true

# Фаервол: разрешаем established, loopback, endpoint, awg0; остальное reject
iptables -I OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT
iptables -I OUTPUT -d "$endpoint_ip" -p udp --dport "$endpoint_port" -j ACCEPT
iptables -A OUTPUT -o "$interface" -j ACCEPT
iptables -A OUTPUT -j REJECT

trap 'awg-quick down /tmp/awg0.conf' INT TERM EXIT
while :; do sleep 3600; done