#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2086

set -ae

function prepare_source_balena() {
    if [ -n "$BALENA_DEVICE_UUID" ]; then
        mkdir -p sources transforms
        envsubst <templates/sources/journald.yaml.template >sources/journald.yaml
        envsubst <templates/transforms/source-balena.yaml.template >transforms/source-balena.yaml
    fi
}

function prepare_source_kubernetes() {
    if [ -n "$KUBERNETES_SERVICE_HOST" ]; then
        VECTOR_BUFFER_TYPE=${VECTOR_BUFFER_TYPE:-disk}
        VECTOR_BUFFER_WHEN_FULL=${VECTOR_BUFFER_WHEN_FULL:-block}
        mkdir -p sources
        envsubst <templates/sources/source-kubernetes.yaml.template >sources/source-kubernetes.yaml
    fi
}

function write_to_file() {
    VARIABLE=$1
    FILE_PATH=$2
    if [[ -f "${VARIABLE}" ]]; then
        # Copy the file if a path is set as value
        cp -f "${VARIABLE}" "${FILE_PATH}"
    else
        # Write the variable value into file if in base64 or multi-line string
        echo "${VARIABLE}" | base64 -d >"${FILE_PATH}" 2>/dev/null || echo "${VARIABLE}" >"${FILE_PATH}"
    fi
}

function prepare_sink_vector() {
    mkdir -p sinks

    # Set default values here
    VECTOR_ACKNOWLEDGEMENTS_ENABLED=${VECTOR_ACKNOWLEDGEMENTS_ENABLED:-true}
    VECTOR_BUFFER_TYPE=${VECTOR_BUFFER_TYPE:-memory}
    VECTOR_BUFFER_WHEN_FULL=${VECTOR_BUFFER_WHEN_FULL:-drop_newest}
    # Temporarily handle old environment variable names
    test -n "$VECTOR_BUFFER_MAX_EVENTS" && VECTOR_BUFFER_MEMORY_MAX_EVENTS=${VECTOR_BUFFER_MAX_EVENTS}
    test -n "$VECTOR_BUFFER_MAX_SIZE" && VECTOR_BUFFER_DISK_MAX_SIZE=${VECTOR_BUFFER_MAX_SIZE}
    VECTOR_BUFFER_MEMORY_MAX_EVENTS=${VECTOR_BUFFER_MEMORY_MAX_EVENTS:-1000}
    VECTOR_BUFFER_DISK_MAX_SIZE=${VECTOR_BUFFER_DISK_MAX_SIZE:-268435488}
    VECTOR_COMPRESSION_ENABLED=${VECTOR_COMPRESSION_ENABLED:-true}
    VECTOR_REQUEST_TIMEOUT_SECS=${VECTOR_REQUEST_TIMEOUT_SECS:-300}

    # Prepare the configuration file
    if [ -n "${VECTOR_ENDPOINT}" ]; then
        envsubst <templates/sinks/sink-vector.yaml.template >sinks/sink-vector.yaml
        if [ -n "${VECTOR_TLS_CA_FILE}" ]; then
            VECTOR_TLS_ENABLED=true
            VECTOR_TLS_VERIFY_CERTIFICATE=${VECTOR_TLS_VERIFY_CERTIFICATE:-true}
            VECTOR_TLS_VERIFY_HOSTNAME=${VECTOR_TLS_VERIFY_HOSTNAME:-true}
            envsubst <templates/sinks/sink-vector.yaml.template >sinks/sink-vector.yaml
            write_to_file "${VECTOR_TLS_CA_FILE}" "${CERTIFICATES_DIR}/ca.pem"
            sed -i 's|#ca_file:|ca_file:|g' sinks/sink-vector.yaml
            if [ -n "${VECTOR_TLS_CRT_FILE}" ] && [ -n "${VECTOR_TLS_KEY_FILE}" ]; then
                write_to_file "${VECTOR_TLS_CRT_FILE}" "${CERTIFICATES_DIR}/client.pem"
                write_to_file "${VECTOR_TLS_KEY_FILE}" "${CERTIFICATES_DIR}/client-key.pem"
                sed -i 's|#crt_file:|crt_file:|g' sinks/sink-vector.yaml
                sed -i 's|#key_file:|key_file:|g' sinks/sink-vector.yaml
                sed -i 's|#verify_certificate:|verify_certificate:|g' sinks/sink-vector.yaml
                sed -i 's|#verify_hostname:|verify_hostname:|g' sinks/sink-vector.yaml
            fi
        else
            VECTOR_TLS_ENABLED=false
            envsubst <templates/sinks/sink-vector.yaml.template >sinks/sink-vector.yaml
        fi

        if [[ "${VECTOR_BUFFER_TYPE}" == 'disk' ]]; then
            sed -i 's|#max_size:|max_size:|g' sinks/sink-vector.yaml
        else
            sed -i 's|#max_events:|max_events:|g' sinks/sink-vector.yaml
        fi
    fi
}

function start_vector() {
    # https://vector.dev/docs/administration/validating/
    find /etc/vector -name "*.y*ml" -exec cat {} \;
    vector validate --config-dir /etc/vector &&
        vector --config-dir /etc/vector
}

if [[ "$DISABLED" =~ true|True|TRUE|yes|Yes|YES|on|On|ON|1 ]]; then
    echo 'logs-to-vector has been disabled. This service is now idle.'
    sleep infinity
else
    BALENA_FLEET_NAME=${BALENA_APP_NAME}
    CERTIFICATES_DIR=/etc/vector/certificates
    cd /etc/vector
    prepare_source_balena
    prepare_source_kubernetes
    prepare_sink_vector
    start_vector
fi
