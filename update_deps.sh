#!/bin/bash

CADDY_VERSION="v2.10.2"

set -ex

rm go.mod || true
rm go.sum || true

curl https://raw.githubusercontent.com/caddyserver/caddy/refs/heads/master/go.mod -o go.mod
go mod edit -module crccaddyplugin
go mod edit -require github.com/caddyserver/caddy/v2@$CADDY_VERSION
go mod edit -require github.com/prometheus/client_golang@v1.23.2
go mod edit -require github.com/redhatinsights/crcauthlib@v0.5.0
go mod tidy

cp go.mod caddy/
cp go.sum caddy/
cd caddy/
go mod edit -module caddy
go mod edit -replace "github.com/RedHatInsights/crc-caddy-plugin=../"
go mod tidy
go build
./caddy version
./caddy build-info | grep crc-caddy-plugin
rm caddy
