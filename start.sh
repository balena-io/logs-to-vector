#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2086

set -ae

function prepare_vector_sink() {
	VECTOR_TLS_ENABLED=false
	if [ -n "${VECTOR_ENDPOINT}" ]; then
		if [ -n "${VECTOR_TLS_CA_FILE}" ]
		then
			echo "${VECTOR_TLS_CA_FILE}" | base64 -d > "${CERTIFICATES_DIR}/ca.pem"
			sed -i 's|#ca_file:|ca_file:|g' sink-vector.yaml.template
			VECTOR_TLS_ENABLED=true
			if [ -n "${VECTOR_TLS_CRT_FILE}" ] && [ -n "${VECTOR_TLS_KEY_FILE}" ]
			then
				echo "${VECTOR_TLS_CRT_FILE}" | base64 -d > "${CERTIFICATES_DIR}/client.pem"
				sed -i 's|#crt_file:|crt_file:|g' sink-vector.yaml.template
				echo "${VECTOR_TLS_KEY_FILE}" | base64 -d > "${CERTIFICATES_DIR}/client-key.pem"
				sed -i 's|#key_file:|key_file:|g' sink-vector.yaml.template
				VECTOR_TLS_ENABLED=true
			fi
		fi

		if [[ "${VECTOR_TLS_ENABLED}" == 'true' ]]; then
			sed -i 's|#verify_certificate:|verify_certificate:|g' sink-vector.yaml.template
			sed -i 's|#verify_hostname:|verify_hostname:|g' sink-vector.yaml.template
		fi
		# https://stackoverflow.com/a/31926346/1559300
		cat < sink-vector.yaml.template | envsubst > sink-vector.yaml
fi
}

function start_vector() {
	# https://vector.dev/docs/administration/validating/
	cat /etc/vector/*.y*ml \
	&& vector validate --config-yaml "/etc/vector/*.y*ml" \
	&& vector --config-yaml "/etc/vector/*.y*ml"
}


BALENA_FLEET_NAME=${BALENA_APP_NAME}
CERTIFICATES_DIR=/etc/vector/certificates

cd /etc/vector
prepare_vector_sink
start_vector
