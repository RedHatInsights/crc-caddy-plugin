#!/bin/bash

# This script will download go.mod from caddyserver's master branch
# and resync this project's dependencies to match

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

cd caddy/
./build.sh
rm caddy
