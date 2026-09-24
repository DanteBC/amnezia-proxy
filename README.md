# AmneziaWG 3.1 HTTP + SOCKS5 прокси

Docker Compose стек с пользователем туннелем AmneziaWG 3.1 и аутентифицированными прокси HTTP CONNECT и SOCKS5.

## Быстрый старт

1. Поместите конфигурацию клиента AmneziaWG 3.1 в `config/amnezia3.conf`.
2. Скопируйте `.env.example` в `.env` и измените `PROXY_PASSWORD`.
3. Запустите стек:

```sh
docker compose up -d
```

Первый запуск может занять до значения `HEALTH_VPN_DURATION_INITIAL`, пока устанавливается туннель.

## Точки доступа

- HTTP/HTTPS прокси: `http://HOST:${HTTP_PROXY_PORT:-3128}`
- SOCKS5 прокси: `socks5://HOST:${SOCKS_PROXY_PORT:-1080}`

Для обоих протоколов требуется тот же логин и пароль из `.env`. HTTPS-проксификация выполняется через HTTP CONNECT.

## Исключения из маршрутизации VPN (`NO_VPN_ROUTES`)

Параметр `NO_VPN_ROUTES` задает список IP-адресов и CIDR-сетей, помимо встоенных RFC1918, которые должны обходить VPN и подключаться напрямую, даже когда активен туннель. Это полезно, когда сам прокси или его клиенты обращаются к нему по публичному IP, а также для исключения локальных сетей и других адресов, которые нельзя отправлять через VPN.

Пример:

```dotenv
NO_VPN_ROUTES=228.91.16.20/32,10.0.0.5,192.168.10.0/24
```

Значения указываются через запятую. В дополнение к стандартным RFC1918-диапазонам можно явно добавить адрес, по которому вы обращаетесь к прокси снаружи (публичный IP хоста, IP клиента и т.п.).

## Белый список назначения

Задайте `PROXY_WHITELIST` в `.env` как список IP-адресов, CIDR или шаблонов доменов через запятую:

```dotenv
PROXY_WHITELIST=api.ipify.org,z.ai,*.z.ai,cursor.com,*.cursor.com,*.cursor.sh,*.cursor-cdn.com,*.cursorapi.com,*.cursorvm.com,*.*.cursorvm.com
```

Список проверяется `3proxy` до открытия соединения и применяется как к HTTP CONNECT, так и к SOCKS5. Пустое значение запрещает все назначения. Для доменов укажите основной домен и явный шаблон `*.` в случае, если нужны и корневой домен, и поддомены, например `example.com,*.example.com`.

После изменения списка пересоздайте ACL-контейнер:

```sh
docker compose up -d --build --force-recreate acl-proxy
```

## Примечания по конфигурации

Файл монтируется в `/etc/amnezia/awg0.conf` и используется локальной реализацией AWG 3.1 в userspace. Это должна быть конфигурация AmneziaWG INI с секциями `[Interface]` и `[Peer]`; не коммитьте её, потому что в ней находятся приватные ключи.

Образ VPN собирается из текущих исходников `amneziawg-go` и `amneziawg-tools`. Entrypoint разрешает hostname удалённой точки в IPv4-адрес, запускает `awg-quick` через `amneziawg-go` и применяет kill-switch, который разрешает только туннельную конечную точку и трафик через `awg0`.

Полная конфигурация AWG 3.1 передаётся целиком, включая `HeaderProtectionKey`, `ContentPaddingAddition`, параметры таймингов, `RandomTrailers` и `DisableCookies`. Внутри используется `Table = off`, потому что Docker Desktop не позволяет использовать sysctl для policy-routing из ядра, который нужен для `awg-quick`; entrypoint создаёт маршрут по умолчанию через `awg0` после сохранения маршрута до конечной точки VPN.

Состояние туннеля и прокси-контейнера можно проверить через `docker compose ps` и `docker compose logs -f proxy`.

## Полезные команды

```sh
docker compose config
docker compose ps
docker compose logs -f proxy
docker compose down
```
