#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2086

set -ae

function prepare_source_balena() {
	if [ -n "$BALENA_DEVICE_UUID" ]
	then
		mkdir -p sources transforms
		cp -f templates/sources/journald.yaml.template sources/journald.yaml
		cp -f templates/transforms/source-balena.yaml.template transforms/source-balena.yaml
	fi
}

function prepare_source_kubernetes() {
	if [ -n "$KUBERNETES_SERVICE_HOST" ]
	then
		mkdir -p sources
		cp -f templates/sources/source-kubernetes.yaml.template sources/source-kubernetes.yaml
	fi
}

function prepare_sink_vector() {
	mkdir -p sinks
	VECTOR_COMPRESSION_ENABLED=${VECTOR_COMPRESSION_ENABLED:-true}
	VECTOR_TLS_ENABLED=false
	VECTOR_REQUEST_TIMEOUT_SECS=${VECTOR_REQUEST_TIMEOUT_SECS:-300}
	if [ -n "${VECTOR_ENDPOINT}" ]; then
		if [ -n "${VECTOR_TLS_CA_FILE}" ]
		then
			echo "${VECTOR_TLS_CA_FILE}" | base64 -d > "${CERTIFICATES_DIR}/ca.pem"
			sed -i 's|#ca_file:|ca_file:|g' templates/sinks/sink-vector.yaml.template
			VECTOR_TLS_ENABLED=true
			if [ -n "${VECTOR_TLS_CRT_FILE}" ] && [ -n "${VECTOR_TLS_KEY_FILE}" ]
			then
				echo "${VECTOR_TLS_CRT_FILE}" | base64 -d > "${CERTIFICATES_DIR}/client.pem"
				sed -i 's|#crt_file:|crt_file:|g' templates/sinks/sink-vector.yaml.template
				echo "${VECTOR_TLS_KEY_FILE}" | base64 -d > "${CERTIFICATES_DIR}/client-key.pem"
				sed -i 's|#key_file:|key_file:|g' templates/sinks/sink-vector.yaml.template
				VECTOR_TLS_ENABLED=true
			fi
		fi

		if [[ "${VECTOR_TLS_ENABLED}" == 'true' ]]; then
			sed -i 's|#verify_certificate:|verify_certificate:|g' templates/sinks/sink-vector.yaml.template
			sed -i 's|#verify_hostname:|verify_hostname:|g' templates/sinks/sink-vector.yaml.template
		fi
		# https://stackoverflow.com/a/31926346/1559300
		cat < templates/sinks/sink-vector.yaml.template | envsubst > sinks/sink-vector.yaml
fi
}

function start_vector() {
	# https://vector.dev/docs/administration/validating/
	cat /etc/vector/*.y*ml \
	&& vector validate --config-dir /etc/vector \
	&& vector --config-dir /etc/vector
}


if [[ "$DISABLED" =~ true|True|TRUE|yes|Yes|YES|on|On|ON|1 ]]; then
	echo 'Logshipper has been disabled. This service is now idle.'
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
