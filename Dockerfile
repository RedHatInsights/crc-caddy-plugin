FROM registry.access.redhat.com/hi/go:1.26.10-builder@sha256:8534a929a08031ad051058a3573ebd9f2e7c187314e406dc2815070c64c445a2 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM registry.access.redhat.com/hi/caddy:latest@sha256:e8cc32ec0044dd7fea9acf1084f4d0efbd7a0e220e51cc16e395199c7fcc8574

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
