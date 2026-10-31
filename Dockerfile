FROM registry.access.redhat.com/hi/go:1.26.10-builder@sha256:67b65bbb377e8602b248d3c83fb4a4b1ba14216b461af444da70fdcc3e47b5b2 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM registry.access.redhat.com/hi/caddy:latest@sha256:a6e3943eadee8926586733bb5646c2ea57189b4d0a88ac0a1d7c8d86d8f5c00b

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
