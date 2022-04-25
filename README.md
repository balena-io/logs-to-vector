# logshipper

A log collection agent that ships logs from the balena engine to a downstream
log aggregator.  It uses [Vector][vector] as an agent to collect the logs from
journald, add labels to the logs, and send the logs to a log aggregator.

The agent currently ships logs to the following log aggregators:
- [Vector][vector]


## Usage

To use this image, create a service in your `docker-compose.yml` as shown below:
```
version: "2.1"

volumes:
  logshipper: {}

logshipper:
    image: bh.cr/balenablocks/logshipper
    labels:
      io.balena.features.journal-logs: '1'
    restart: unless_stopped
    volumes:
      - logshipper:/var/lib/logshipper
```

You can also set your docker-compose.yml to build from a Dockerfile.template file. 
You may add your own Vector sinks that takes `balena` as input.

*docker-compose.yml*:
```
version: "2.1"

volumes:
  logshipper: {}

services:
  logshipper:
    build: ./
    labels:
      io.balena.features.journal-logs: '1'
    restart: unless_stopped
    volumes:
      - logshipper:/var/lib/logshipper
```

*Dockerfile.template*
```
FROM bh.cr/balenablocks/logshipper

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

`bh.cr/balenablocks/logshipper` can be configured via the following variables:

| Environment Variable        | Default | Description                                          |
| --------------------------- | ------  | -----------------------------------------------------|
| `VECTOR_ENDPOINT`           | ``      | The endpoint of the vector log aggregator            |
| `VECTOR_TLS_CA_FILE`        | ``      | An additional CA certificate file encoded in base 64 |
| `VECTOR_TLS_CRT_FILE`       | ``      | The client certificate file encoded in base 64       |
| `VECTOR_TLS_KEY_FILE`       | ``      | The client certificate key file encoded in base 64   |
| `VECTOR_VERIFY_CERTIFICATE` | `false` | Enables TLS certificate verification.                |

You can refer to the [docs](https://www.balena.io/docs/learn/manage/serv-vars/#environment-and-service-variables) on how to set environment or service variables

Alternatively, you can set them in the `docker-compose.yml` or `Dockerfile.template` files.

[vector]: https://vector.dev
