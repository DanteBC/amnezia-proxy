# AmneziaWG 3.1 HTTP + SOCKS5 proxy

Docker Compose stack with an AmneziaWG 3.1 userspace tunnel and authenticated HTTP CONNECT and SOCKS5 proxies.

## Quick start

1. Put the AmneziaWG 3.1 client configuration in `config/amnezia3.conf`.
2. Copy `.env.example` to `.env` and change `PROXY_PASSWORD`.
3. Start the stack:

```sh
docker compose up -d
```

The first start can take up to the configured `HEALTH_VPN_DURATION_INITIAL` while the tunnel is established.

## Endpoints

- HTTP/HTTPS proxy: `http://HOST:${HTTP_PROXY_PORT:-3128}`
- SOCKS5 proxy: `socks5://HOST:${SOCKS_PROXY_PORT:-1080}`

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

The file is mounted at `/etc/amnezia/awg0.conf` and is consumed by the local AWG 3.1 userspace implementation. It must be an AmneziaWG INI configuration, including `[Interface]` and `[Peer]`; do not commit it because it contains private keys.

The VPN image is built from the current `amneziawg-go` and `amneziawg-tools` sources. The entrypoint resolves the endpoint hostname to an IPv4 address, starts `awg-quick` with `amneziawg-go`, and applies a kill-switch that only permits the tunnel endpoint and traffic through `awg0`.

The complete AWG 3.1 configuration is passed through, including `HeaderProtectionKey`, `ContentPaddingAddition`, timing parameters, `RandomTrailers`, and `DisableCookies`. `Table = off` is used internally because Docker Desktop does not allow the kernel policy-routing sysctl used by `awg-quick`; the entrypoint installs the default route through `awg0` after preserving the route to the VPN endpoint.

Tunnel and proxy container health are visible in `docker compose ps` and `docker compose logs -f proxy`.

## Useful commands

```sh
docker compose config
docker compose ps
docker compose logs -f proxy
docker compose down
```
