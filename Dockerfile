FROM registry.access.redhat.com/ubi9/go-toolset:1.25.5-1769430014 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM quay.io/redhat-services-prod/hcm-eng-prod-tenant/caddy-ubi:8335391c36f9943e8a2de24924ecd79df966cca9

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
