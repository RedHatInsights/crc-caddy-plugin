# CRC Caddy Plugin

A Caddy v2 HTTP middleware plugin that provides authentication and authorization for ConsoleDot ephemeral environments. The plugin integrates with the BOP (Basic or Protected) authentication service and validates user identities via [crcauthlib][crcauthlib-repo].

This Caddy image presents a reverse proxy to an individual service. It is intended to run as a sidecar container in the same pod as the service it authenticates, deployed via the [Clowder operator][clowder-repo].

## Prerequisites

- Go 1.25.5 or later
- Docker or Podman (for container builds)
- Access to a BOP/MBOP authentication service

## Installation

This plugin is distributed as a Go module and packaged into a custom Caddy binary. To use it in your own Caddy build:

### Option 1: Using xcaddy

```sh
xcaddy build --with github.com/RedHatInsights/crc-caddy-plugin
```

### Option 2: Custom main.go

1. Create a `main.go` file:

```go
package main

import (
    caddycmd "github.com/caddyserver/caddy/v2/cmd"
    _ "github.com/RedHatInsights/crc-caddy-plugin"
    _ "github.com/caddyserver/caddy/v2/modules/standard"
)

func main() {
    caddycmd.Main()
}
```

2. Build:

```sh
go mod init caddy
go mod tidy
go build
```

### Option 3: Container Image

Pull the pre-built container image from quay.io:

```sh
podman pull quay.io/redhat-services-prod/hcm-eng-prod-tenant/caddy-ubi:latest
```

## Configuration

The Caddy CRC plugin has three configuration options:

```caddyfile
:8080 {
    log
    tls internal

    crcauth {
        output stdout
        bop http://my-bop-server
        whitelist /api/unauth,/api/unauth-dir/file
    }
    reverse_proxy 127.0.0.1:{$CADDY_PORT}
}
```

### Configuration Options

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `output` | string | Yes | Log stream destination: `stdout` or `stderr` |
| `bop` | string | Yes | BOP server URL (e.g., `http://my-bop-server`). Provides Basic Auth validation endpoint and JWT public certificate |
| `whitelist` | string | No | Comma-separated list of API path prefixes that bypass authentication (e.g., `/api/health,/metrics`) |

### Authentication Flow

1. Request arrives at Caddy on port 8080
1. Plugin checks if path matches whitelist → if yes, skip auth
1. Plugin attempts Basic Auth validation via BOP
1. Plugin attempts JWT validation via BOP public certificate
1. On success: request is proxied to backend service at `127.0.0.1:$CADDY_PORT` with identity header injected
1. On failure: 401 or 403 response with JSON error

## Development

### Setup

Clone the repository:

```sh
git clone https://github.com/RedHatInsights/crc-caddy-plugin.git
cd crc-caddy-plugin
```

Install dependencies:

```sh
go mod download
```

### Building the Plugin

Build the custom Caddy binary:

```sh
cd caddy
./build.sh
```

This script:
1. Copies `go.mod` and `go.sum` from the parent directory
1. Modifies the module name to `caddy`
1. Replaces the plugin import with a local path
1. Builds the binary
1. Verifies the plugin is included via `caddy build-info`

### Building the Container Image

Build the multi-stage Docker image:

```sh
docker build -t crc-caddy-plugin:local .
```

The Dockerfile uses a two-stage build:
1. **Build stage**: Compiles the Go binary in a Go 1.25.5 container
1. **Runtime stage**: Packages the binary in a Red Hat UBI9 minimal image

### Testing

No automated tests are currently available. Testing is performed manually against ephemeral environments.

## Deployment

The plugin is deployed in Red Hat ephemeral environments via the [Clowder operator][clowder-repo]. It runs as a sidecar container in the same pod as the service it authenticates.

### CI/CD

Continuous integration is handled by Tekton Pipelines via Konflux:

- **PR validation**: `.tekton/crc-caddy-plugin-pull-request.yaml`
- **Image publishing**: `.tekton/crc-caddy-plugin-push.yaml` (on push to `master` branch)

Images are published to `quay.io` (Red Hat container registry).

## Architecture

For detailed information on internal design decisions, dependency points, and tradeoffs, see [ARCHITECTURE.md][architecture].

## Authentication Library

This repository contains the Caddy plugin module. The actual authentication logic is implemented in the [crcauthlib repository][crcauthlib-repo], which handles:

- Basic Auth credential validation via BOP
- JWT token signature verification via BOP public certificate
- Identity extraction and validation

## Contributing

See [CONTRIBUTING.md][contributing] for guidelines on contributing to this project.

## License

This project does not currently have a LICENSE file. For licensing questions, contact the RedHatInsights team.

[crcauthlib-repo]: https://github.com/redhatinsights/crcauthlib
[clowder-repo]: https://github.com/RedHatInsights/clowder
[architecture]: ./ARCHITECTURE.md
[contributing]: ./CONTRIBUTING.md
