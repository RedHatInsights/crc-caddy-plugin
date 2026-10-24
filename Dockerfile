FROM registry.access.redhat.com/hi/go:1.26.10-builder@sha256:4162773224c8cb37a037cb7aef4665456b091f5b7ef01c6f15a465eb6341a66d AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM registry.access.redhat.com/hi/caddy:latest@sha256:8a03f687a6866d136daefed47dc2926522264b4267385e77fade8f072eb3fee0

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
