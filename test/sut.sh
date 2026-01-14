#!/bin/sh

set -eu

echo "Waiting for logs..."
timeout=0
# Wait up to ~30s (15 * 2s) for the last line to arrive
while ! grep "line_index=20" /data/received.ndjson 2>/dev/null; do
    if [ "$timeout" -ge 15 ]; then
        echo "FAIL: Timed out waiting for logs."
        exit 1
    fi
    echo "Still waiting for line_index=20..."
    sleep 2
    timeout=$((timeout+1))
done
echo "Trace: Received last log line."

echo "Verifying strict line order..."
for i in $(seq 1 20); do
    # Extract line $i from received.ndjson and check for "line_index=$i"
    # sed -n "${i}p" prints exactly the i-th line.
    if ! sed -n "${i}p" /data/received.ndjson | grep -q "line_index=$i"; then
        echo "FAIL: Line $i order mismatch or missing."
        echo "Expected line_index=$i but got: $(sed -n "${i}p" /data/received.ndjson)"
        exit 1
    fi
done

echo "PASS: All 20 lines verified in correct order."
