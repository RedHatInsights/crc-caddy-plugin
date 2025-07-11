FROM registry.access.redhat.com/ubi8/go-toolset:1.23.6-4 as build

RUN mkdir /opt/app-root/src/crccaddyplugin
WORKDIR /opt/app-root/src/crccaddyplugin

COPY caddyplugin.go .
RUN set -exu ; \
    go mod init crccaddyplugin; \
    go get github.com/caddyserver/caddy/v2@v2.9.1; \
    go mod tidy;

RUN mkdir /opt/app-root/src/caddy
WORKDIR /opt/app-root/src/caddy

COPY main.go.template ./main.go

RUN set -ex; \
  go mod init caddy; \
  go get github.com/caddyserver/caddy/v2@v2.9.1; \
  go mod edit -replace "github.com/RedHatInsights/crc-caddy-plugin=/opt/app-root/src/crccaddyplugin"; \
  go mod tidy ;\
  go build;

FROM quay.io/redhat-services-prod/hcm-eng-prod-tenant/caddy-ubi:0d6954b

COPY Caddyfile /etc/caddy/Caddyfile
COPY candlepin-ca.pem /cas/ca.pem
COPY --from=build /opt/app-root/src/caddy/caddy /usr/bin/caddy
