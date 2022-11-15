# logs-to-vector

A log collection agent that ships logs from the balena engine to a downstream
log aggregator.  It uses [Vector][vector] as an agent to collect the logs from
journald, add labels to the logs, and send the logs to a log aggregator.

Important: Starting v1.0.0, logs-to-vector now uses Vector API v2 which is incompatible
with Vector API v1.  If you are using a Vector API v1 endpoint, please use
logs-to-vector v0.2.1 instead.

The agent currently ships logs to the following log aggregators:
- [Vector][vector]


## Usage

To use this image, create a service in your `docker-compose.yml` as shown below:
```
version: "2.1"

volumes:
  logs-to-vector: {}

logs-to-vector:
    image: bh.cr/balenablocks/logs-to-vector
    labels:
      io.balena.features.journal-logs: '1'
    restart: unless_stopped
    volumes:
      - logs-to-vector:/var/lib/logs-to-vector
```

You can also set your docker-compose.yml to build from a Dockerfile.template file. 
You may add your own Vector sinks that takes `balena` as input.

*docker-compose.yml*:
```
version: "2.1"

volumes:
  logs-to-vector: {}

services:
  logs-to-vector:
    build: ./
    labels:
      io.balena.features.journal-logs: '1'
    restart: unless_stopped
    volumes:
      - logs-to-vector:/var/lib/logs-to-vector
```

*Dockerfile.template*
```
FROM bh.cr/balenablocks/logs-to-vector

COPY sink.yaml /etc/vector
```

*sink.yaml*
```
sinks:
  console:
    type: console
    inputs:
      - balena
```


## Customisation

`bh.cr/balenablocks/logs-to-vector` can be configured via the following variables:

| Environment Variable            | Default  | Description                                                |
| ------------------------------- | -------- | ---------------------------------------------------------- |
| `DISABLE`                       | `false`  | Disables the logs-to-vector service                            |
| `VECTOR_BUFFER_MAX_EVENTS`      | `1000`   | The maximum number of events allowed in the buffer         |
| `VECTOR_BUFFER_MAX_SIZE`        | `268435488` | The maximum size of the buffer on the disk              |
| `VECTOR_BUFFER_TYPE`            | `memory` | The type of buffer to use                                  |
| `VECTOR_BUFFER_WHEN_FULL`       | `drop_newest` | The behavior when the buffer becomes full.            |
| `VECTOR_COMPRESSION_ENABLED`    | `true`   | Enables gRPC compression with gzip                         |
| `VECTOR_ENDPOINT`               | ``       | The endpoint of the vector log aggregator                  |
| `VECTOR_REQUEST_TIMEOUT_SECS`   | `300`    | The maximum time a request can take before being aborted   |
| `VECTOR_TLS_CA_FILE`            | ``       | An additional CA certificate file encoded in base 64       |
| `VECTOR_TLS_CRT_FILE`           | ``       | The client certificate file encoded in base 64             |
| `VECTOR_TLS_KEY_FILE`           | ``       | The client certificate key file encoded in base 64         |
| `VECTOR_TLS_VERIFY_CERTIFICATE` | `true`   | Verifies the TLS certificate of the remote hos             |
| `VECTOR_TLS_VERIFY_HOSTNAME`    | `true`   | Verifies the endpoint hostname against the TLS certificate |

You can refer to the [docs](https://www.balena.io/docs/learn/manage/serv-vars/#environment-and-service-variables) on how to set environment or service variables

Alternatively, you can set them in the `docker-compose.yml` or `Dockerfile.template` files.

[vector]: https://vector.dev
