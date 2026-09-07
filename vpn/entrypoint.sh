#!/bin/sh
set -eu

config=/gluetun/amneziawg/awg0.conf

value() {
  awk -v key="$1" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      line = $0
      sub(/^[[:space:]]*[^=]+=[[:space:]]*/, "", line)
      print line
      exit
    }
  ' "$config"
}

endpoint=$(value Endpoint)
endpoint_host=${endpoint%:*}
endpoint_port=${endpoint##*:}
endpoint_ip=$(getent ahostsv4 "$endpoint_host" | awk 'NR == 1 { print $1 }')

[ -n "$endpoint_ip" ] || {
  printf '%s\n' "Could not resolve AmneziaWG endpoint: $endpoint_host" >&2
  exit 1
}

export AMNEZIAWG_ENDPOINT_IP="$endpoint_ip"
export AMNEZIAWG_ENDPOINT_PORT="$endpoint_port"
export AMNEZIAWG_PUBLIC_KEY=$(value PublicKey)
export AMNEZIAWG_PRIVATE_KEY=$(value PrivateKey)
export AMNEZIAWG_PRESHARED_KEY=$(value PresharedKey)
export AMNEZIAWG_ADDRESSES=$(value Address)
export AMNEZIAWG_JC=$(value Jc)
export AMNEZIAWG_JMIN=$(value Jmin)
export AMNEZIAWG_JMAX=$(value Jmax)
export AMNEZIAWG_S1=$(value S1)
export AMNEZIAWG_S2=$(value S2)
export AMNEZIAWG_S3=$(value S3)
export AMNEZIAWG_S4=$(value S4)
export AMNEZIAWG_H1=$(value H1)
export AMNEZIAWG_H2=$(value H2)
export AMNEZIAWG_H3=$(value H3)
export AMNEZIAWG_H4=$(value H4)

exec /gluetun-entrypoint
