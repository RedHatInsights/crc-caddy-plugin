# Architecture

This document describes the internal architecture of the CRC Caddy plugin, key design decisions, and dependency relationships.

## Overview

The CRC Caddy plugin is a middleware module for the Caddy v2 HTTP server. It provides authentication and authorization for ConsoleDot ephemeral environments by integrating with the BOP (Basic or Protected) authentication service and validating user identities via [crcauthlib][crcauthlib-repo].

## Module Structure

The plugin follows Caddy's [plugin architecture][caddy-extending], registering itself as an HTTP handler directive (`crcauth`) that processes requests before they reach the reverse proxy backend.

### Core Components

| Component | File | Responsibility |
|-----------|------|----------------|
| Middleware | `caddyplugin.go:53-60` | Main plugin struct; holds configuration (`Output`, `BOP`, `Whitelist`) and auth validator instance |
| Handler | `caddyplugin.go:100-280` | HTTP request processing; implements authentication flow and metrics tracking |
| Binary Entry | `caddy/main.go:33-43` | Caddy binary entry point; imports plugin and standard modules |

### Request Flow

1. **Registration**: Plugin registers as `http.handlers.crcauth` directive via `init()` at `caddyplugin.go:48-51`
1. **Provisioning**: Caddy calls `Provision()` to initialize output writer and `crcauthlib.CRCAuthValidator` instance with BOP URL
1. **Request Handling**: `ServeHTTP()` intercepts requests:
   - Checks if request path is in the whitelist → bypass auth
   - Attempts Basic Auth validation via BOP
   - Attempts JWT validation via BOP public certificate
   - On success: injects identity header and proxies to backend
   - On failure: returns 401 or 403 with JSON error response
1. **Metrics**: Prometheus histograms track response latency and duration per API/status code

## Dependencies

### External Dependencies

| Dependency | Purpose | Critical Path |
|-----------|---------|---------------|
| [Caddy v2][caddy-repo] | HTTP server framework | Plugin lifecycle, config parsing, HTTP handling |
| [crcauthlib][crcauthlib-repo] | Authentication logic | All auth validation (Basic + JWT) |
| [Prometheus client][prometheus-client] | Metrics collection | Request latency/duration histograms |

### Internal Dependency Points

- **Authentication delegation**: Plugin does not implement auth logic; it fully delegates to `crcauthlib.CRCAuthValidator`
- **BOP integration**: All identity verification (Basic Auth username/password check, JWT public cert fetching) is routed through the BOP service URL
- **No local state**: Plugin is stateless; relies on BOP for session/token validity

## Design Decisions

### Tradeoff: Stateless Middleware

**Decision**: Plugin maintains no session cache or token store.

**Rationale**: Ephemeral environments are short-lived; caching adds complexity and stale-data risk without meaningful performance gain. BOP is treated as the single source of truth.

**Impact**: Every request triggers an authentication check (Basic Auth credential validation or JWT signature verification). This increases BOP load but ensures auth decisions reflect real-time BOP state.

### Tradeoff: Whitelist-Based Bypass

**Decision**: Whitelist is prefix-based and comma-separated, applied at request time without path normalization.

**Rationale**: Simple configuration for common use cases (e.g., `/api/health`, `/metrics`). Path normalization (e.g., URL decoding, trailing slash handling) was deemed unnecessary for ephemeral environment use cases.

**Impact**: Operators must specify exact path prefixes in the whitelist. Ambiguous paths (e.g., `/api/foo` vs `/api/foo/`) require explicit entries.

### Tradeoff: Prometheus Metrics Granularity

**Decision**: Metrics track latency and duration with `api` and `status` labels.

**Rationale**: Enables per-endpoint SLO monitoring and status code distribution analysis without high-cardinality explosion.

**Impact**: Custom bucket ranges (`[15, 30, 60, 180, 240, 960, 1800]` seconds) are optimized for slow ephemeral backends; not suitable for low-latency production services.

## Build and Deployment

### Custom Caddy Binary

The plugin is built into a custom Caddy binary using the [xcaddy][xcaddy-repo] pattern:

1. `caddy/main.go` imports `github.com/RedHatInsights/crc-caddy-plugin` as a blank import
1. `caddy/build.sh` compiles the Go module into a single `caddy` executable
1. Multi-stage Dockerfile builds the binary and packages it in a Red Hat UBI9 container

### Container Image

- **Base image**: `quay.io/redhat-services-prod/hcm-eng-prod-tenant/caddy-ubi:latest`
- **Registry**: quay.io (Red Hat container registry)
- **CI/CD**: Tekton Pipelines via Konflux (see `.tekton/crc-caddy-plugin-push.yaml`)

### Deployment Target

The container is deployed in Red Hat ephemeral environments via the [Clowder operator][clowder-repo]. It runs as a sidecar in the same pod as the service it authenticates, proxying traffic from `:8080` (Caddy) to `127.0.0.1:$CADDY_PORT` (service).

## Known Limitations

- **No test coverage**: Explicit in `pr_check.sh:21`: "bypass Jenkins junit checks for now, we have no tests running..."
- **No certificate rotation**: BOP public certificate is fetched once during provisioning; certificate updates require pod restart
- **No rate limiting**: Plugin does not implement request rate limiting; relies on upstream API gateways
- **No audit logging**: Authentication events (success/failure) are logged to `stdout`/`stderr` but not structured for SIEM ingestion

## Future Considerations

- Add unit tests for whitelist matching and request flow
- Implement certificate refresh on TTL expiration
- Add structured logging (JSON) for audit trail

[crcauthlib-repo]: https://github.com/redhatinsights/crcauthlib
[caddy-repo]: https://github.com/caddyserver/caddy
[caddy-extending]: https://caddyserver.com/docs/extending-caddy
[prometheus-client]: https://github.com/prometheus/client_golang
[xcaddy-repo]: https://github.com/caddyserver/xcaddy
[clowder-repo]: https://github.com/RedHatInsights/clowder
