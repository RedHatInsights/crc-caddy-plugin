# AI Agent Instructions

This file provides guidance for AI agents working with the crc-caddy-plugin repository.

## Project Overview

The CRC Caddy plugin is a middleware module for Caddy v2 HTTP server that provides authentication and authorization for Red Hat ConsoleDot ephemeral environments. It integrates with the BOP (Basic or Protected) authentication service and delegates identity validation to [crcauthlib][crcauthlib-repo]. The plugin is distributed as both a Go module (`github.com/RedHatInsights/crc-caddy-plugin`) and a containerized Caddy binary deployed via the [Clowder operator][clowder-repo] as a sidecar in ephemeral environment pods.

## Dependencies

**Runtime:**
- Caddy (HTTP server framework; plugin lifecycle and config parsing)
- crcauthlib (authentication logic; Basic Auth and JWT validation)
- Prometheus client_golang (metrics collection for request latency/duration)

**Build:**
- Go 1.25.9
- Docker/Podman (multi-stage container builds)

**CI/CD:**
- Tekton Pipelines via Konflux (`.tekton/crc-caddy-plugin-push.yaml`, `.tekton/crc-caddy-plugin-pull-request.yaml`)

## Development Commands

See [Development Setup][readme-dev] in the README for the full command reference.

**Install dependencies:**
```sh
go mod download
```

**Build the custom Caddy binary:**
```sh
cd caddy
./build.sh
```

This script copies `go.mod`/`go.sum` from the parent directory, modifies the module name to `caddy`, replaces the plugin import with a local path, and builds the binary.

**Build the container image:**
```sh
docker build -t crc-caddy-plugin:local .
```

**Note:** No automated tests are currently available. The `pr_check.sh` script explicitly states: "bypass Jenkins junit checks for now, we have no tests running..." Testing is performed manually against ephemeral environments.

## Architecture

The plugin registers as a Caddy HTTP handler directive (`crcauth`) via `init()` in `caddyplugin.go`. The `Middleware` struct holds configuration (`Output`, `BOP`, `Whitelist`) and a `crcauthlib.CRCAuthValidator` instance. The `ServeHTTP()` handler intercepts requests, checks whitelist, attempts Basic Auth or JWT validation via BOP, injects identity headers on success, and proxies to the backend service. Prometheus metrics track response latency and duration per API/status code.

For detailed design decisions, dependency points, and tradeoffs, see [ARCHITECTURE.md][architecture].

## Code Style

**Language version:** Go 1.25.9

**Formatting:** Standard Go formatting conventions apply. No explicit linter configuration (`.golangci.yml`) is present in the repository.

**Import structure:** Follow standard Go import grouping (stdlib, third-party, local).

**Caddyfile syntax:** Plugin directive is `crcauth` with three options: `output` (stdout/stderr), `bop` (BOP server URL), and `whitelist` (comma-separated path prefixes).

## Common Mistakes

1. **Do not assume test coverage exists.** The repository has no `*_test.go` files and `pr_check.sh` explicitly bypasses test checks. Do not suggest running `go test` or reference non-existent test suites.

2. **Whitelist matching is prefix-based without normalization.** The `whitelist` configuration is comma-separated and matches request paths as-is. Do not assume URL decoding, trailing slash handling, or case-insensitive matching. Ambiguous paths (e.g., `/api/foo` vs `/api/foo/`) require explicit entries.

3. **BOP is the single source of auth truth.** The plugin is stateless and does not cache credentials, tokens, or JWT certificates. Every request triggers an authentication check via BOP. Do not suggest adding local caching or session storage without understanding the ephemeral environment tradeoff (see [ARCHITECTURE.md][architecture] § Stateless Middleware).

4. **Custom Caddy binary build pattern.** The `caddy/build.sh` script uses a specific module replacement pattern. Do not modify `caddy/main.go` or the build script without understanding the xcaddy-style build workflow. The script modifies `go.mod` in-place during the build process.

5. **No linter configs exist in CI.** While you may find references to linting best practices, no `.golangci.yml`, `.golangci-lint.toml`, or similar files are present. Do not assume CI enforces linting checks beyond what is defined in `.tekton/` pipeline files.

[crcauthlib-repo]: https://github.com/redhatinsights/crcauthlib
[clowder-repo]: https://github.com/RedHatInsights/clowder
[architecture]: ./ARCHITECTURE.md
[readme-dev]: ./README.md#development
