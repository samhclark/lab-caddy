ARG CADDY_VERSION=2.11
ARG CLOUDFLARE_VERSION=0.2.2

FROM docker.io/library/caddy:${CADDY_VERSION}-builder@sha256:5fa9a318e2f32bf2c75f59eb4bad9b3e1b8522fbce9a689a6a7d4614145672f3 AS builder

ARG CLOUDFLARE_VERSION

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    xcaddy build --with github.com/caddy-dns/cloudflare@v${CLOUDFLARE_VERSION}

FROM docker.io/library/caddy:${CADDY_VERSION}@sha256:80ebbf75eed465e30dc532cf359df21465ae5f6ab827a2218435e36a030d1bc7

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
