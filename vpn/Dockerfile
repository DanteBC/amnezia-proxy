FROM golang:1.25-alpine AS awg-go

RUN apk add --no-cache git make build-base linux-headers
RUN git clone --depth 1 https://github.com/amnezia-vpn/amneziawg-go.git /src/amneziawg-go \
    && cd /src/amneziawg-go \
    && make

FROM alpine:3.22 AS awg-tools

RUN apk add --no-cache git make build-base linux-headers bash iproute2 iptables
RUN git clone --depth 1 https://github.com/amnezia-vpn/amneziawg-tools.git /src/amneziawg-tools \
    && make -C /src/amneziawg-tools/src \
    && make -C /src/amneziawg-tools/src install PREFIX=/usr

FROM alpine:3.22

RUN apk add --no-cache bash iproute2 iptables bind-tools openresolv
COPY --from=awg-go /src/amneziawg-go/amneziawg-go /usr/local/bin/amneziawg-go
COPY --from=awg-tools /usr/bin/awg /usr/bin/awg
COPY --from=awg-tools /usr/bin/awg-quick /usr/bin/awg-quick
COPY entrypoint.sh /usr/local/bin/amneziawg-entrypoint.sh
RUN chmod 755 /usr/local/bin/amneziawg-entrypoint.sh /usr/local/bin/amneziawg-go /usr/bin/awg /usr/bin/awg-quick

ENTRYPOINT ["/usr/local/bin/amneziawg-entrypoint.sh"]