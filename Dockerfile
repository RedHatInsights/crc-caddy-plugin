FROM registry.access.redhat.com/hi/go:1.26.5-builder@sha256:b163b5484b7b776b285d851414039ed21fc358f4249ecb2901e0f1ba2db2e9b6 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM registry.access.redhat.com/hi/caddy:latest@sha256:f4e737d9b4360c468d0b4b94b2d9e61e23f0c00317d2949eb8665b3a7fa8b63e

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
