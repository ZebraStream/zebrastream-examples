#!/usr/bin/env bash
# A simple bash producer client for Zebrastream
# https://www.zebrastream.io
#
# Simplifications:
# - no check if producer command fails - no latency added
# - producer command supports no shell features (e.g. pipes, redirections), use a wrapper script if needed

set -euo pipefail
export LC_ALL=C

# Check if producer command was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <producer command...>" >&2
    echo "Example: $0 tail -f /var/log/syslog" >&2
    exit 1
fi

# Configuration via environment variables with defaults
: "${ZEBRASTREAM_ACCESSTOKEN:?Missing required env var ZEBRASTREAM_ACCESSTOKEN}"
: "${ZEBRASTREAM_PATH:?Missing required env var ZEBRASTREAM_PATH}"
: "${ZEBRASTREAM_CONNECT_URL:=https://connect.zebrastream.io/v0}"
: "${ZEBRASTREAM_MAX_RETRIES:=5}"
: "${ZEBRASTREAM_RETRY_DELAY:=5}"
: "${ZEBRASTREAM_CONTENT_TYPE:=text/plain}"

bearer="${ZEBRASTREAM_ACCESSTOKEN}"
path="${ZEBRASTREAM_PATH}"
connect_url="${ZEBRASTREAM_CONNECT_URL}"
producer_cmd="$*"

# Logging function
log() {
    local level="$1"
    shift
    echo "$(date -Iseconds) [$level] $*" >&2
}

# Cleanup handler
cleanup() {
    log INFO "Cleaning up processes..."
    pkill -P $$ || true
    exit 0
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Exponential backoff function
retry_with_backoff() {
    local max_attempts="$1"
    local attempt=1
    local delay="${ZEBRASTREAM_RETRY_DELAY}"

    until "$2" || [ "$attempt" -eq "$max_attempts" ]; do
        log WARN "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
        sleep "$delay"
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done

    if [ "$attempt" -eq "$max_attempts" ]; then
        log ERROR "Max attempts reached"
        return 1
    fi
}

# Main loop
while true; do
    while true; do
        log INFO "Starting new session"
        
        # Connect with retry logic
        connect_to_server() {
            stream_url="$(curl --silent --request GET --fail \
                              --no-buffer --http1.1 \
                              --connect-timeout 10 \
                              --header "Authorization: Bearer ${bearer}" \
                              "${connect_url}${path}?mode=await-reader")"
            test -n "${stream_url}"
        }

        if retry_with_backoff "${ZEBRASTREAM_MAX_RETRIES}" connect_to_server; then
            break
        else
            log ERROR "Failed to establish connection"
            exit 1
        fi
    done

    # Transfer payload via stream address
    log INFO "Sending data to '${stream_url}'"
    (
        # Execute command directly instead of using eval
        "$@" || {
            log ERROR "Producer command failed with exit code $?"
            exit 1
        }
    ) |
    curl --silent --fail \
         -w '%{http_code} %{http_version} %{url_effective}\n' \
         --request PUT \
         --upload-file . \
         --no-buffer \
         --http1.1 \
         --connect-timeout 10 \
         --expect100-timeout 180 \
         --header "Authorization: Bearer ${bearer}" \
         --header "Content-Type: ${ZEBRASTREAM_CONTENT_TYPE}" \
         "${stream_url}" || {
        log ERROR "Upload failed with exit code $?"
    }
done
