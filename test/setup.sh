#!/bin/sh

set -eu

rm -rf /data/*

apk add --no-cache openssl

mkdir -p /data/certs
cd "/data/certs" || exit 1

# 1. Generate CA
openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
    -keyout ca.key -out ca.crt -subj "/CN=TestCA"

# 2. Generate Server Cert (Aggregator)
# SAN (Subject Alt Name) is required for "aggregator" hostname verification
openssl req -newkey rsa:2048 -nodes -keyout server.key \
    -out server.csr -subj "/CN=aggregator"
echo "subjectAltName=DNS:aggregator" > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out server.crt -days 365 -extfile server.ext

# 3. Generate Client Cert (Logs-to-Vector)
openssl req -newkey rsa:2048 -nodes -keyout client.key \
    -out client.csr -subj "/CN=client"
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out client.crt -days 365

chmod 644 /data/certs/*

# 4. Generate Log Data
for i in $(seq 1 20); do
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") line_index=$i" >> /data/input.log
done
tail -n1 /data/input.log

echo "SETUP: Certs and Data Ready."
touch /data/ready
exec sleep infinity
