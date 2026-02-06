#!/bin/bash

cp ../go.mod .
cp ../go.sum .
go mod edit -module caddy
go mod edit -replace "github.com/RedHatInsights/crc-caddy-plugin=../"
go mod tidy
go build
./caddy version
./caddy build-info | grep crc-caddy-plugin
