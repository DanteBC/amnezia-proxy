#!/bin/sh
set -eu

username=${PROXY_USERNAME:?PROXY_USERNAME is required}
password=${PROXY_PASSWORD:?PROXY_PASSWORD is required}
whitelist=${PROXY_WHITELIST:-}

http_service="http://0.0.0.0:8888"
socks_service="socks5://0.0.0.0:1080"

exec /bin/gost -DD -L "$http_service" -L "$socks_service"
