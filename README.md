# Amnezia VPN HTTP + SOCKS5 proxy

Docker Compose stack with an AmneziaWG tunnel, authenticated HTTP CONNECT and SOCKS5 proxies, and Prometheus monitoring.

## Quick start

1. Put the client configuration exported by Amnezia in `config/amnezia.conf`.
2. Copy `.env.example` to `.env` and change `PROXY_PASSWORD`. AmneziaWG values are read automatically from `config/amnezia.conf`.
3. Start the stack:

```sh
docker compose up -d
```

The first start can take up to the configured `HEALTH_VPN_DURATION_INITIAL` while the tunnel is established.

## Endpoints

- HTTP/HTTPS proxy: `http://HOST:${HTTP_PROXY_PORT:-3128}`
- SOCKS5 proxy: `socks5://HOST:${SOCKS_PROXY_PORT:-1080}`
- Prometheus UI: `http://HOST:${PROMETHEUS_PORT:-9090}`
- Gluetun metrics: `http://HOST:${PROMETHEUS_METRICS_PORT:-9091}/metrics`

The same username and password from `.env` are required for both proxy protocols. HTTPS proxying is provided through HTTP CONNECT.

## Destination whitelist

Set `PROXY_WHITELIST` in `.env` as a comma-separated list of destination IPs, CIDRs, or hostname patterns:

```dotenv
PROXY_WHITELIST=api.ipify.org,z.ai,*.z.ai,cursor.com,*.cursor.com,*.cursor.sh,*.cursor-cdn.com,*.cursorapi.com,*.cursorvm.com,*.*.cursorvm.com
```

The list is enforced by 3proxy before a connection is opened and applies to both HTTP CONNECT and SOCKS5. An empty value denies all destinations. For domains, include the bare domain and an explicit `*.` pattern when both the apex and subdomains are needed, for example `example.com,*.example.com`.

After changing the list, recreate the ACL container:

```sh
docker compose up -d --build --force-recreate acl-proxy
```

## Configuration notes

The file is mounted at `/gluetun/amneziawg/awg0.conf`, which is the custom AmneziaWG configuration location supported by Gluetun. It must be an AmneziaWG INI configuration, including `[Interface]` and `[Peer]`; do not commit it because it contains private keys.

The Compose entrypoint reads the AmneziaWG keys, address, endpoint, and obfuscation parameters directly from `config/amnezia.conf` and exports them only to Gluetun at startup. The endpoint hostname is resolved to an IPv4 address automatically because Gluetun requires an explicit endpoint IP.

GSO is disabled for the AmneziaWG interface to avoid oversized UDP batches (`sendmmsg: message too long`) on hosts whose path MTU differs from the Docker network MTU. The interface MTU is read from the Amnezia configuration.

`FIREWALL_OUTBOUND_SUBNETS` is optional and should only contain trusted local networks that must remain reachable outside the VPN. Keep it empty unless required. It is separate from `PROXY_WHITELIST`: the former changes VPN firewall routing, while the latter limits proxy destinations.

## Monitoring

Prometheus scrapes Gluetun at `proxy:9090/metrics`. Tunnel and proxy container health are also visible in `docker compose ps` and `docker compose logs -f proxy`.

The Gluetun control server is intentionally not published on the host. If an external monitor must query it, publish `8000:8000` only on a trusted interface and set `CONTROL_SERVER_AUTH_DEFAULT_ROLE` to a basic-auth JSON role, for example:

```dotenv
CONTROL_SERVER_AUTH_DEFAULT_ROLE={"auth":"basic","username":"monitor","password":"change-this-too"}
```

Do not expose the control server directly to the Internet.

## Useful commands

```sh
docker compose config
docker compose ps
docker compose logs -f proxy
docker compose down
```
