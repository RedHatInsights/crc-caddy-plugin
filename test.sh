#!/bin/bash
set -euo pipefail

SKIP_BUILD=false
CONTAINER_ENGINE="${CONTAINER_ENGINE:-docker}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build) SKIP_BUILD=true; shift ;;
        *) IMAGE_NAME="$1"; shift ;;
    esac
done

IMAGE_NAME="${IMAGE_NAME:-crc-caddy-plugin:test}"
PASS=0
FAIL=0

run_test() {
    local name="$1"
    shift
    echo -n "  $name ... "
    if output=$("$@" 2>&1); then
        echo "PASS"
        PASS=$((PASS + 1))
    else
        echo "FAIL"
        echo "    Output: $output"
        FAIL=$((FAIL + 1))
    fi
}

if [[ "$SKIP_BUILD" == "false" ]]; then
    echo "Building image as $IMAGE_NAME ..."
    $CONTAINER_ENGINE build -t "$IMAGE_NAME" . >/dev/null 2>&1
    echo "Build successful."
    echo ""
fi

echo "Running tests against $IMAGE_NAME ..."
echo ""

echo "[Image structure]"
run_test "caddy binary exists" \
    $CONTAINER_ENGINE run --rm "$IMAGE_NAME" caddy version

run_test "crc-caddy-plugin is compiled in" \
    bash -c "$CONTAINER_ENGINE run --rm '$IMAGE_NAME' caddy build-info 2>&1 | grep -q 'crc-caddy-plugin'"

run_test "crcauth module is registered" \
    bash -c "$CONTAINER_ENGINE run --rm '$IMAGE_NAME' caddy list-modules 2>&1 | grep -q 'http.handlers.crcauth'"

echo ""
echo "[Configuration]"
run_test "Caddyfile parses successfully" \
    bash -c "$CONTAINER_ENGINE run --rm -e CADDY_BOP_URL=http://localhost:8080 -e CADDY_WHITELIST='/api/test*' -e CADDY_PORT=8000 '$IMAGE_NAME' caddy adapt --config /etc/caddy/Caddyfile 2>/dev/null | head -1 | grep -q 'apps'"

run_test "crcauth handler is in adapted config" \
    bash -c "$CONTAINER_ENGINE run --rm -e CADDY_BOP_URL=http://localhost:8080 -e CADDY_WHITELIST='/api/test*' -e CADDY_PORT=8000 '$IMAGE_NAME' caddy adapt --config /etc/caddy/Caddyfile 2>/dev/null | head -1 | grep -q '\"handler\":\"crcauth\"'"

echo ""
echo "[Security]"
run_test "runs as non-root user" \
    bash -c "[[ \$($CONTAINER_ENGINE inspect '$IMAGE_NAME' --format '{{.Config.User}}') != '' && \$($CONTAINER_ENGINE inspect '$IMAGE_NAME' --format '{{.Config.User}}') != 'root' && \$($CONTAINER_ENGINE inspect '$IMAGE_NAME' --format '{{.Config.User}}') != '0' ]]"

run_test "no shell available (distroless)" \
    bash -c "! $CONTAINER_ENGINE run --rm --entrypoint='' '$IMAGE_NAME' sh -c 'echo vulnerable' 2>/dev/null"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
