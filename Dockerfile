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

FROM registry.access.redhat.com/hi/caddy:latest@sha256:68379841431e2bed714876e1fabd3339c121291a8d223816103da43eaf20a9da

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
