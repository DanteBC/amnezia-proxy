#!/bin/sh
set -eu

config=/tmp/3proxy.cfg
username=${PROXY_USERNAME:?PROXY_USERNAME is required}
password=${PROXY_PASSWORD:?PROXY_PASSWORD is required}
whitelist=${PROXY_WHITELIST:-}

print_rules() {
  if [ "$whitelist" = '*' ]; then
    printf 'allow %s * * *\n' "$username"
    return
  fi

  if [ -n "$whitelist" ]; then
    old_ifs=$IFS
    IFS=,
    for address in $whitelist; do
      [ -n "$address" ] && printf 'allow %s * %s *\n' "$username" "$address"
    done
    IFS=$old_ifs
  fi
}

{
  printf 'nscache 65536\n'
  printf 'log\n'
  printf 'auth strong\n'
  printf 'users "%s:CL:%s"\n' "$username" "$password"

  print_rules
  printf 'deny * * * *\n'
  printf 'proxy -p8888\n'

  printf 'flush\n'
  printf 'auth strong\n'
  print_rules
  printf 'deny * * * *\n'
  printf 'socks -p1080\n'
} > "$config"

exec /bin/3proxy "$config"
