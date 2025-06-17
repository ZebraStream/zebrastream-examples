#!/usr/bin/env bash
# A simple bash producer client for Zebrastream
# https://www.zebrastream.io
#
# Simplifications:
# - no check if producer command fails - no latency added
# - producer command supports no shell features (e.g. pipes, redirections), use a wrapper script if needed
# - API and network failures are determined by curl exit code and command duration (less than ZEBRASTREAM_MIN_DISCONNECT_SECONDS) 

set -euo pipefail
export LC_ALL=C

# Check if producer command was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <producer command...>" >&2
    echo "Example: $0 tail -f /var/log/syslog" >&2
    exit 1
fi

# Configuration via environment variables with defaults
: "${ZEBRASTREAM_ACCESSTOKEN:?Missing required env var ZEBRASTREAM_ACCESSTOKEN}"  # write access token for authentication
: "${ZEBRASTREAM_PATH:?Missing required env var ZEBRASTREAM_PATH}"  # path to the stream
: "${ZEBRASTREAM_CONNECT_URL:=https://connect.zebrastream.io/v0}"  # default connection URL
: "${ZEBRASTREAM_MAX_RETRIES:=5}"  # maximum number of retries for establishing a connection in case of errors
: "${ZEBRASTREAM_RETRY_DELAY:=5}"  # initial delay in seconds for retrying connection attempts
: "${ZEBRASTREAM_MIN_DISCONNECT_SECONDS:=60}"  # minimum runtime in seconds to consider a disconnect
: "${ZEBRASTREAM_CONTENT_TYPE:=text/plain}"  # content type for the data being sent
: "${ZEBRASTREAM_READ_MODE:=blocking}"  # read mode for the stream

# Validate read mode
case "${ZEBRASTREAM_READ_MODE}" in
    blocking|nonblocking) ;;
    *)
        log ERROR "Invalid ZEBRASTREAM_READ_MODE '${ZEBRASTREAM_READ_MODE}'. Must be 'blocking' or 'nonblocking'"
        exit 1
        ;;
esac

# Set curl upload mode based on read mode
upload_source=$([ "${ZEBRASTREAM_READ_MODE}" = "blocking" ] && echo "-" || echo ".")

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

# Retry function with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local attempt=1
    local delay="${ZEBRASTREAM_RETRY_DELAY}"
    local min_runtime="${ZEBRASTREAM_MIN_DISCONNECT_SECONDS}"

    while true; do
        local start_time="$(date +%s)"
        if "$2"; then
            return 0
        fi
        local end_time="$(date +%s)"
        local runtime="$((end_time - start_time))"

        if [ $runtime -ge $min_runtime ]; then
            log INFO "Command ran for ${runtime}s, treating as disconnect and reconnecting..."
            attempt=1
            delay="${ZEBRASTREAM_RETRY_DELAY}"
            continue
        fi

        if [ "$attempt" -eq "$max_attempts" ]; then
            log WARN "Attempt $attempt/$max_attempts failed, stopping..."
            log ERROR "Max attempts reached"
            return 1
        fi

        log WARN "Attempt $attempt/$max_attempts failed, retrying in ${delay}s..."
        sleep "$delay"
        attempt=$((attempt + 1))
        delay=$((delay * 2))
    done
}

# Main loop
while true; do
    while true; do
        log INFO "Starting new connect session"
        
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
         --upload-file "${upload_source}" \
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
