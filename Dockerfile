FROM docker.io/library/alpine:3.16 AS builder

RUN apk add --no-cache ca-certificates

RUN mkdir -p \
    /config/caddy \
    /data/caddy \
    /etc/caddy \
    /usr/share/caddy

# https://github.com/caddyserver/caddy/releases
ENV CADDY_VERSION v2.6.2

RUN set -eux; \
	apkArch="$(apk --print-arch)"; \
	binArch='amd64'; \
	checksum='ae18c0facae7c8ee872492a1ba63a4c7608915d6d9fe267aef4f869cf65ebd4b7f9ff57f609aff2bd52db98c761d877b574aea2c0c9ddc2ec53d0d5e174cb542'; \
	wget -O /tmp/caddy.tar.gz "https://github.com/caddyserver/caddy/releases/download/v2.6.2/caddy_2.6.2_linux_${binArch}.tar.gz"; \
	echo "$checksum  /tmp/caddy.tar.gz" | sha512sum -c; \
	tar x -z -f /tmp/caddy.tar.gz -C /usr/bin caddy; \
	rm -f /tmp/caddy.tar.gz; \
	chmod +x /usr/bin/caddy; \
	caddy version

FROM gcr.io/distroless/static-debian11:nonroot

LABEL org.opencontainers.image.title=lab-caddy
LABEL org.opencontainers.image.description="Preconfigured Caddy instance for my own homelab"
LABEL org.opencontainers.image.licenses=Apache-2.0
LABEL org.opencontainers.image.source=https://github.com/samhclark/lab-caddy

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

COPY --from=builder /usr/bin/caddy   /usr/bin/caddy
COPY --from=builder /data/caddy      /data/caddy
COPY --from=builder /etc/caddy       /etc/caddy
COPY --from=builder /usr/share/caddy /usr/share/caddy
COPY --from=builder --chown=nonroot:nonroot /config/caddy    /config/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html /usr/share/caddy/index.html

EXPOSE 8080
EXPOSE 4443
EXPOSE 4443/udp

WORKDIR /srv

ENTRYPOINT ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
