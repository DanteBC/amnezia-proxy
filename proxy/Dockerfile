FROM gogost/gost@sha256:e1ff429eb07d5f820ed08b2593599f63d03b9f670631d9394b7bf5e068fb9e4c

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh && apk add --no-cache busybox-extras

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
