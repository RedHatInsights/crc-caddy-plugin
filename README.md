# CRC Caddy Image

The CRC Caddy Image is used in the ephemeral environments to emulate the authentications used on ConsoleDot. It is deployed via the [Clowder](https://github.com/RedHatInsights/clowder) operator. The functionality is provided as a Caddy plugin.

It runs in one of two modes:

* **Side Car Mode** - where the configuration is taken from `/etc/Caddyfile`
* **Gateway Mode** - where configuration is taken from `/etc/caddy/Caddyfile.json`

## Side Car Mode
The **Side Car Mode** configuration is in this repository and presents a simple reverse proxy to an individual service. The intention for this image mode is for the container to be run inside the same pod as the service it provides authentication for.

## Gateway Mode
The **Gateway Mode** expects configuration to be mounted at `/etc/caddy/Caddyfile.json`. The app is intended to run as a stand-alone pod which serves as a gateway that handles authentication/routing to multiple paths/services.

## Configuration
The Caddy CRC plugin has three configuration options, an example of which is shown below:

```
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

* `output` - defines where the output of the log stream goes, either `stdout` or `stderr`
* `bop` - defines the host:port for the BOP server, or MBOP in the case of ephemeral environments
  * For Basic Auth BOP provides and endpoint to check the credentials
  * For JWT Auth BOP provides the JWT public cert used to validate the credentials
* `whitelist` - defines a list of paths that will not be authenticated as a comma separated list

## crcauthlib
This repo houses the repository for the caddy plugin itself. The actual code that performs all the auth operations is housed in the [crcauthlib repo](https://github.com/redhatinsights/crcauthlib/).
