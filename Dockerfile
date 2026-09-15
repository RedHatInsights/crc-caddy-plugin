FROM registry.access.redhat.com/hi/go:1.26.5-builder@sha256:aef155087940a9221c59ca48ad8af371a4c1a46b05f0283737149cb00ef484b3 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM registry.access.redhat.com/hi/caddy:latest@sha256:6eef6872ac960bdd1256670ffacfe249fa4306dbbf6d4a4dd02984c3203ae0cc

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
