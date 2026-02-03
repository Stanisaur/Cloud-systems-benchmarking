#!/bin/bash
# Contains the cleanup function to remove all created resources.

cleanup() {
    log_info "Interruption received, cleaning up all benchmark resources ---"
    # Unset the trap to prevent infinite loops on cleanup errors
    trap - ERR

    if [ -d "$STATE_DIR" ]; then
        log_info "1. Removing client and gateway containers..."
        # Using cat and xargs is robust for a large number of containers
        cat "$STATE_DIR"/*.txt 2>/dev/null | xargs -P 4 -n 20 --no-run-if-empty docker rm -f >/dev/null 2>&1
    fi

    log_info "2. Removing gateways by name (idempotent step)..."
    for (( i=1; i<=NUM_IPS; i++ )); do
        docker rm -f "snat_gateway_${i}" >/dev/null 2>&1
    done

    log_info "3. Removing Docker networks..."
    for (( i=1; i<=NUM_IPS; i++ )); do
        docker network rm "${MOBILE_NETWORK_PREFIX}_${i}" >/dev/null 2>&1
    done
    docker network rm macvlan_net >/dev/null 2>&1

    log_info "4. Removing temporary state directory..."
    if [ -d "$STATE_DIR" ]; then
        rm -rf "$STATE_DIR"
    fi

    if [ -n "$CLIENT_CREDS_FILE_PATH" ] && [ -f "$CLIENT_CREDS_FILE_PATH" ]; then
        rm -f "$CLIENT_CREDS_FILE_PATH"
        log_info "Removed temporary client credentials file."
    fi
    
    log_success "--- Cleanup Complete ---"
    exit 0
}