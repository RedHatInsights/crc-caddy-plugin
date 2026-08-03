FROM registry.access.redhat.com/ubi9/go-toolset:1.25.9-1778675823 AS build

WORKDIR /opt/app-root/src

COPY caddyplugin.go .
COPY go.mod .
COPY go.sum .

RUN mkdir caddy
WORKDIR /opt/app-root/src/caddy

COPY caddy/main.go .
COPY caddy/build.sh .

RUN bash build.sh

FROM quay.io/redhat-services-prod/hcm-eng-prod-tenant/caddy-ubi@sha256:aa3bd9e7ae5a183a46fab829aa3eda1ab3fa8ac7f6b2291dee14e48c1ec8c74c

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
